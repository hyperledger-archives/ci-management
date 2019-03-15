Global Macros
=============

The purpose of writing global macros is use across the repositories and
reduce the redundant code. These macros are easy to manage.

SCM
---

**The scm module allows referencing multiple repositories in a Jenkins
job**

**gerrit-trigger-scm**

-  This macro is used to get the GERRIT_REFSPEC on every freestyle
   verify job. Below are the required and optional parameters for this
   macro. This macro is used to get the GERRIT_REFSPEC of the patchset
   on top of the parent commit of the patchset.

   **Required Parameters:**

   base-dir:
   :math:`BASE_DIR` (gopath/src/github.com/hyperledger/$PROJECT) or
   specify the directory path to clone the repository.

   **Optional Parameters:**

   GERRIT_BRANCH - Gerrit_branch is a jenkins environment variable
   contains the branch name to build against GERRIT_REFSPEC - RefSpec
   number ex: refs/changes/32/30032/1

**gerrit-trigger-scm-merge**

-  This macro is used to get the GERRIT_REFSPEC on every freestyle merge
   job. Below are the required and optional parameters for this macro.
   This macro is used to get the latest commit from the repository
   instead of GERRIT_REFSPEC of the patchset.

   **Required Parameters:**

::

    base-dir: $BASE_DIR (gopath/src/github.com/hyperledger/$PROJECT) or specify the directory path to clone
    the repository.

     **Optional Parameters:**

     GERRIT_BRANCH - Gerrit_branch is a jenkins environment variable contains the branch name to build against
     GERRIT_REFSPEC - RefSpec number ex: refs/changes/32/30032/1 (default: blank)

     When manually building the job, replace the GERRIT_REFSPEC parameter with the Gerrit patchset 
     reference number of the patch. You can specify the GERRIT_BRANCH to test specific changes

## Wrappers

**Wrappers can alter the way the build is run as well as the build
output.**

**build-timeout**

-  This wrapper is used to set the build timeout in freestyle jobs.

   ::

       wrappers:
         - build-timeout:
             timeout: '{build_timeout}'

   See example here
   https://github.com/hyperledger/ci-management/blob/master/jjb/fabric-sdk-py/fabric-sdk-py-jobs.yaml

   **Required Parameters:**

   -  timeout: Set timeout in mins from job configuration. ex:
      build_timeout: 50

**hyperledger-infra-wrappers**

-  This wrapper is required for all jobs as it configures the wrappers
   needed by all Hyperledger infra. This sets the ``timestamps``,
   ``mask-passwords``, ``ansicolor``, ``openstack: single-use: true``
   and set ``ssh-agent-credentials user to hyperledger-jobbuilder``

   ::

       wrappers:
         - hyperledger-infra-wrappers

Triggers
--------

**Triggers define what causes a Jenkins job to start building.**

**gerrit-trigger-patch-submitted**

-  This macro will trigger the Jenkins jobs when a patchset is created.

   This macro triggers a jenkins job when a change-merged-event is
   triggered It won’t trigger the job when a commit message is updated
   in the gerrit patchset. Triggers the jobs when a comment is posted in
   the gerrit patchset. Comments are specified in the job configuration.
   It triggers the job on a branch pattren specified in the job
   configuration.

   ::

       triggers:
         - gerrit-trigger-patch-submitted:
             name: '{project}'
             branch: 'master'
             trigger-comment1: 'reverify-x$'
             trigger-comment2: 'reverify$'

   **Required Parameters:**

   project: Provide project name from the job configuration.

**gerrit-trigger-patch-merged**

-  This macro will trigger the Jenkins jobs when a patchset is merged.

   **Required Parameters:**

   name: Project Name ex: fabric or $PROJECT environment variable

   branch: Provide the branch name. Provide blank value if you would
   like trigger jon on any branch.

   Sample job configuration. See this example
   https://github.com/hyperledger/ci-management/blob/master/jjb/fabric-sdk-java/fabric-sdk-java-jobs.yaml
  
  ::
         triggers: 
           - gerrit-trigger-patch-merged: name: ‘{project}’
               branch: ''

**gerrit-comment-trigger**

-  This macro is used to trigger builds based on the comment provided in
   the gerrit patchset. Meaning when you use this macro in a job
   configuration, this won’t trigger a job until you post a comment in
   gerrit patchset to trigger a job. Also, this macro skips the gerrit
   vote for any build result.

   ::

       triggers:
         - gerrit-comment-trigger:
             name: '{project}'
             branch: ''
             trigger-comment: 'Run UnitTest'

   **Required Parameters:**

   name: Project Name ex: fabric

   branch: Provide the branch name. Provide blank value if you would
   like trigger jon on any branch.

   trigger-comment: Provide the comment for which you would like to
   trigger the job.

**gerrit-trigger-tag**

-  This macro will trigger the Jenkins jobs when a tag is created.

   ::

       triggers:
         - gerrit-trigger-tag:
             name: '{project}'
             branch: 'master'

   **Required Parameters:**

   name: Project Name ex: fabric

   branch: Provide the branch name. Provide blank value if you would
   like trigger jon on any branch.

Publishers:
-----------

**Publishers define actions that the Jenkins job should perform after
the build is complete.**

**log-artifacts**

-  This macro is used to collects the log files with extension .log and
   keep it in the WORKSPACE directory. Also, this macro won’t fail the
   build if .log files are missing in the build.

   ::

       publishers:
         - log-artifacts

**archive-artifacts**

-  This macro is used to publish the artifacts provided in the on the
   jenkins console.

   ::

       publishers:
         - archive-artifacts:
             artifacts: '.tox/**/*.log'

   The above macro archives the ``.log`` files and display on the
   jenkins console.

**code-coverage-report**

-  This macro is used to read the report-file and publish the cobuertura
   code coverage report on the Jenkins job console. The threshold limit
   is hard coded in this macro. Please refer the macro for more details
   on the threshold limit.

   ::

        publishers:
          - code-coverage-report

**test-logs**

-  This macro is used to collects the artifacts
   ``**/*.csv, **/*.log, **/*.xml`` and archive on the jenkins build
   artifacts section.

   ::

        publishers:
          - test-logs

**fabric-email-notification**

-  This macro is used to publish the build notifications through email
   to the list of email-ids sp

   ::

       publishers:
         - fabric-email-notification:
             email-ids: 'sambhavdutt@gmail.com, vijaypunugubati@gmail.com'
             output_format: ''
             developer-email: 'developers'

   **Required Parameters:**

   email-ids: Provide the email-ids list here to send the email
   notification to. output_format: provide the log file type

## Builders

**Builders define actions that the Jenkins job should execute**

**provide-maven-settings**

-  This macro is used to provide the configuration files.

   ::

       builders:
         - provide-maven-settings:
             global-settings-file: 'global-settings'
             fabric-settings-file: '{mvn-settings}'

   **Required Parameters:**

   mvn-settings: provide the value to this variable. Each project has
   it’s own maven-settings file. See example here
   ``mvn-settings: 'fabric-ca-settings'`` if it fabric, pass
   ``fabric-settings`` to maven-settings variable.

**docker-login** (Dependent on provide-maven-settings macro)

-  This macro is used to perform docker login with nexus credentials to
   publish images to nexus3.

**golang-environment-x86_64**

-  This macro is used to set gopath and goroot for any go related
   projects on x86_64 build nodes. This macro reads the GO_VER value
   from the ci.properties files listed in fabric, fabric-ca repository
   and provide the same to the ``properties-content``.

   ::

       builders:
         - 'golang-environment-{arch}'

   Same applicable to any arch (*s390x* or *ppc64le*)

**output-environment**

-  Display the details of the Jenkins build environment on the Jenkins
   console

   ::

       builders:
         - output-environment

**clean-environment**

-  This macro is used to clean the environment includes deleting
   containers, images (ignoring specific images and tags) and all the
   left over build artifacts before start the build.

   ::

       builders:
         - clean-environment
