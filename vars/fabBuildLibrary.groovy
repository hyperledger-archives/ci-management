#!/usr/bin/env groovy

properties = null

// Load the properties file from the application repository
def loadProperties() {
  Properties prop = new Properties()
  // BASE_DIR points to gopath/src/github.com/$PROJECT
  // GIT_BASE points to git://cloud.hyperledger.org/mirror/$PROJECT.git
  String propertiesFile = readFile("${WORKSPACE}/${BASE_DIR}/ci.properties")
  prop.load(new StringReader(propertiesFile))
  return prop
}

// Cleanup environment before run the tests
def cleanupEnv() {
  try {
    dir("${WORKSPACE}/gopath/src/github.com/hyperledger/ci-management") {
      sh ''' set +x -ue
        echo " ################# "
        echo -e "\033[1m C L E A N - E N V \033[0m"
        echo " ################# "
        if [ -d "ci-management" ]; then
          rm -rf ci-management
        fi
        git clone --single-branch -b master --depth=1 git://cloud.hyperledger.org/mirror/ci-management
        cd ci-management
        ./jjb/common-scripts/include-raw-fabric-clean-environment.sh
      '''
    }
  }
  catch (err) {
    failure_stage = "cleanupEnv"
    currentBuild.result = 'FAILURE'
    throw err
  }
}

// Output all the information about the environment
def envOutput() {
  try {
    sh '''set +x -eu
      echo " ################### "
      echo -e "\033[1m E N V - O U T P U T \033[0m"
      echo " ################### "
      uname -a
      cat /etc/*-release
      gcc --version
      docker version
      docker info
      docker-compose version
      pgrep -a docker
      docker images
      docker ps -a
      env
    '''
  }
  catch (err) {
    failure_stage = "envOutput"
    currentBuild.result = 'FAILURE'
    throw err
  }
}

def cloneRefSpec(project) {
  try {
    def ROOTDIR = pwd()
    if (env.JOB_TYPE != "merge")  {
      // Clone patchset changes on verify Job
      sh '''set +x -eu
        echo " ################################## "
        echo -e "\033[1m F E T C H PATCHSET $GERRIT_REFSPEC \033[0m"
        echo " ################################## "
      '''
      checkout([
        $class: 'GitSCM',
          branches: [[name: '$GERRIT_REFSPEC']],
          extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: '$BASE_DIR'],
            [$class: 'CheckoutOption', timeout: 10]],
          userRemoteConfigs: [[credentialsId: 'hyperledger-jobbuilder', name: 'origin',
            refspec: '$GERRIT_REFSPEC:$GERRIT_REFSPEC',
            url: '$GIT_BASE']]])
    } else {
      // Clone latest merged commit on Merge Job
      sh '''set +x -eu
        echo " #################### "
        echo -e "\033[1m C L O N E - $project \033[0m"
        echo " #################### "
      '''
      checkout([
        $class: 'GitSCM',
          branches: [[name: 'refs/heads/$GERRIT_BRANCH']],
          extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: '$BASE_DIR'],
            [$class: 'CheckoutOption', timeout: 10]],
          userRemoteConfigs: [[credentialsId: 'hyperledger-jobbuilder', name: 'origin',
            refspec: '+refs/heads/$GERRIT_BRANCH:refs/remotes/origin/$GERRIT_BRANCH',
            url: '$GIT_BASE']]])
    }
    dir("$ROOTDIR/$BASE_DIR") {
      sh '''set +x -eu
        echo -e "\033[1m $GERRIT_BRANCH \033[0m"
        echo -e "\033[1m COMMIT LOG \033[0m"
        echo
        echo " ####################### "
        git log -n2 --pretty=oneline --abbrev-commit
        echo " ####################### "
      '''
    }
  } catch (err) {
      failure_stage = "cloneRepo"
      currentBuild.result = 'FAILURE'
      throw err
  }
}

// Pull Docker images from nexus3
def pullDockerImages(fabBaseVersion, fabImages) {
  wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
    try {
      sh """set +x -eu
        echo " ##################### "
        echo -e "\033[1mP U L L - I M A G E S\033[0m"
        echo " ##################### "
        echo "FABRIC_IAMGES: $fabImages"
        echo "BASE_VERSION: $fabBaseVersion"
        echo "MARCH: $MARCH"
        for fabImages in $fabImages; do
          if [ "\$fabImages" = "javaenv" ]; then
            case $MARCH in
              s390x|ppc64le)
                # Do not pull javaenv if ARCH is s390x
                echo "\033[32m ##### Javaenv image not available on $MARCH ##### \033[0m"
                break;
                ;;
              *)
                set -x
                if ! docker pull $NEXUS_REPO_URL/$ORG_NAME-"\$fabImages":$MARCH-$fabBaseVersion-stable > /dev/null; then
                  echo -e "\033[31m ##### FAILED to pull \$fabImages ##### \033[0m"
                  exit 1
                fi
                set +x
                ;;
            esac
          else
            echo "#################################"
            echo -e "\033[1m Pull \$fabImages Image \033[0m"
            echo "#################################"
            set -x
            if ! docker pull $NEXUS_REPO_URL/$ORG_NAME-"\$fabImages":$MARCH-$fabBaseVersion-stable > /dev/null; then
              echo -e "\033[31m ##### FAILED to pull \$fabImages ##### \033[0m"
              exit 1
            fi
            set +x
          fi
          echo -e "\033[1m TAG \$fabImages image \033[0m"
          set -x
          docker tag $NEXUS_REPO_URL/$ORG_NAME-"\$fabImages":$MARCH-$fabBaseVersion-stable $ORG_NAME-"\$fabImages"
          docker tag $NEXUS_REPO_URL/$ORG_NAME-"\$fabImages":$MARCH-$fabBaseVersion-stable $ORG_NAME-"\$fabImages":$MARCH-$fabBaseVersion
          docker tag $NEXUS_REPO_URL/$ORG_NAME-"\$fabImages":$MARCH-$fabBaseVersion-stable $ORG_NAME-"\$fabImages":$fabBaseVersion
          docker rmi -f $NEXUS_REPO_URL/$ORG_NAME-"\$fabImages":$MARCH-$fabBaseVersion-stable
          set +x
        done
        echo
      """
    } catch (err) {
        failure_stage = "pullDockerImages"
        currentBuild.result = 'FAILURE'
        throw err
    }
  }
}

// Pull Thirdparty Docker images from Hyperledger Dockerhub
def pullThirdPartyImages(baseImageVersion, fabThirdPartyImages) {
  wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
    try {
      sh """set +x -eu
        echo " ################################### "
        echo -e "\033[1m P U L L - 3rd P A R T Y I M A G E S \033[0m"
        echo " ################################### "
        echo "THIRDPARTY_IMAGES: $fabThirdPartyImages"
        echo "BASEIMAGE_VERSION: $baseImageVersion"
        for baseImage in $fabThirdPartyImages; do
          set -x
          if ! docker pull $ORG_NAME-\$baseImage:$baseImageVersion > /dev/null; then
            echo -e "\033[31m ##### FAILED to pull \$baseImage ##### \033[0m"
            exit 1
          fi
          docker tag $ORG_NAME-\$baseImage:$baseImageVersion $ORG_NAME-\$baseImage
          set +x
        done
        echo
        docker images | grep hyperledger/fabric
      """
    } catch (err) {
        failure_stage = "pullThirdPartyImages"
        currentBuild.result = 'FAILURE'
        throw err
    }
  }
}
// Pull Binaries into $PROJECT dir
def pullBinaries(fabBaseVersion, fabRepo) {
  wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
    try {
      sh """set +x -eu
        echo " ######################### "
        echo -e "\033[1m P U L L - B I N A R I E S \033[0m"
        echo " ######################### "
        echo "FABRIC_REPO: $fabRepo"
        echo "BASE_VERSION: $fabBaseVersion"
        for fabRepo in $fabRepo; do
          echo "#################################"
          echo "#### Pull \$fabRepo Binaries ####"
          echo "#################################"
          nexusBinUrl=https://nexus.hyperledger.org/content/repositories/snapshots/org/hyperledger/\$fabRepo/hyperledger-\$fabRepo-$fabBaseVersion/$ARCH-$MARCH.$fabBaseVersion-SNAPSHOT
          echo "NEXUS_BIN_URL: \$nexusBinUrl"
          # Download the maven-metadata.xml file
          curl \$nexusBinUrl/maven-metadata.xml > maven-metadata.xml
          if grep -q "not found in local storage of repository" "maven-metadata.xml"; then
            echo  "FAILED: Unable to download from \$nexusBinUrl"
            exit 1
          else
            # Set latest tar file to the ver
            ver=\$(grep value maven-metadata.xml | sort -u | cut -d "<" -f2|cut -d ">" -f2)
            echo "Version: \$ver"
            # Download tar.gz file and extract it
            curl -L \$nexusBinUrl/hyperledger-\$fabRepo-$fabBaseVersion-\$ver.tar.gz | tar xz
            rm hyperledger-\$fabRepo-*.tar.gz
            rm -f maven-metadata.xml
            echo "Finished pulling \$fabRepo"
            echo
          fi
        done
        # List binaries
        echo -e "\033[1m BINARIES \033[0m"
        ls $WORKSPACE/$BASE_DIR/bin
        echo " #################### "
      """
    } catch (err) {
        failure_stage = "pullBinaries"
        currentBuild.result = 'FAILURE'
        throw err
    }
  }
}

// Clone the repository with specific branch name with depth 1(latest commit)
def cloneScm(repoName, branchName) {
  dir("$WORKSPACE/gopath/src/github.com/hyperledger") {
    sh """set +x -eu
      echo " ############### "
      echo -e "\033[1m CLONE $repoName \033[0m"
      echo " ############### "
      if ! git clone --single-branch -b $branchName --depth=1 https://github.com/hyperledger/$repoName; then
        echo -e "\033[31m ##### FAILED to clone $repoName ##### \033[0m"
        exit 1
      fi
      cd $repoName
      workDir=\$(pwd | grep -o '[^/]*\$')
      if [ "\$workDir" = "$repoName" ]; then
        echo " #### COMMIT LOG #### "
        echo " ##################################### "
        git log -n1 --pretty=oneline --abbrev-commit
        echo " ##################################### "
      else
        echo -e "\033[31m ======= FAILED to CLONE $repoName repository ======= \033[0m"
      fi
    """
  }
}
// Build fabric* images
def fabBuildImages(repoName, makeTarget) {
  dir("$WORKSPACE/gopath/src/github.com/hyperledger/$repoName") {
    sh """set +x -ue
      echo " ##################### "
      echo -e "\033[1m B U I L D I M A G E S \033[0m"
      echo " ##################### "
      make clean $makeTarget
    """
  }
}

def deleteUnusedImages() {
  def unusedImages = sh(script: 'docker images | egrep "^dev|^none|^test-vp|^peer[0-9]" | awk \'{print $3}\' | tr \'\n\' \' \'', returnStdout: true).trim()
  println " Images found: " + unusedImages
   if (unusedImages?.trim()) {
    println "Deleting unused images"
    sh 'docker images | egrep "^dev|^none|^test-vp|^peer[0-9]" | awk \'{print $3}\' | xargs docker rmi -f'
  } else {
    println "No unsed images to remove."
  }
  println " ==== Docker Images List ==== "
  sh 'docker images'
}

def deleteContainers() {
  def containerCount = sh(script: 'docker ps -q', returnStdout: true).trim()
  println " Containers found: " + containerCount
  if (containerCount?.trim()) {
    println "Deleting unused containers"
    sh 'docker ps -aq | xargs docker rm -f'
  } else {
    println "No unsed containers to remove."
  }
  println " ==== Docker Container List ==== "
  sh 'docker ps -a'
}
