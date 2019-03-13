Pipeline Verify Job
===================

This document explains how to create Jenkins pipeline verify and merge
jobs with simple configuration changes.

The pipeline verify job template detailed below is a starting point but
we recommend creating your own to ensure that the jobs configured
reflect your project’s needs

Job Templates
-------------

.. _pipeline-verify-job-1:

Pipeline Verify Job
~~~~~~~~~~~~~~~~~~~

::

    - pipeline_verify: &pipeline_verify
        name: pipeline-verify

        project-type: pipeline
        concurrent: true
        pipeline-scm:
          script-path: '{jenkins_file}'
          scm:
            - git:
                credentials-id: 'hyperledger-jobbuilder'
                url: '$GIT_BASE'
                shallow-clone: true
                refspec: $GERRIT_REFSPEC:$GERRIT_REFSPEC
                wipe-workspace: true
                clean:
                  before: true
                  after: true
                branches:
                  - $GERRIT_REFSPEC

        parameters:
          - project-parameter:
              project: '{project}'
          - gerrit-parameter:
              branch: 'master'
          - gerrit-refspec-parameter:
              refspec: '$GERRIT_REFSPEC'

        properties:
          - fabric-pipeline-properties:
              job-type: '{job_type}'
              build-node: 'hyp-{build_node}'
          - build-discarder:
              days-to-keep: 10
              artifact-days-to-keep: 7

        triggers:
          - gerrit-trigger-patch-submitted:
              name: '{project}'
              branch: '{branch}'
              trigger-comment1: 'reverify$'
              trigger-comment2: 'reverify-{build_node}$'

    - job-template:
        name: '{project}-verify-{arch}'
        id: fab-pipeline-verify
    <<: *pipeline_verify

**Template Names:** - ‘{project}-verify-{arch}’

**Names:** - fabric-samples-verify-x86_64

**Comment Trigger:** - Trigger the verify jobs by posting a comment
phrase ``reverify`` and ``reverify-x`` or ``reverify-z`` etc.. based on
the value you provided to ``build_node``

**Required parameters:**

::

    project: fabric-samples  - Project Name
    branch: ''               - Branch Name ex: master/release-1.4 (If you would like to trigger jobs 
    on any branch keep this as default)
    arch: 'x86_64'           - Arch to run builds on
    build_node: 'x'          - Build node label names (hyp-x is for x86_64 build nodes, hyp-z is for 
    s390x build nodes)
    job_type: 'verify'       - Specify the which job type it is, verify is to trigger the verify job
    jenkins_file: Jenkinsfile- Specify the Jenkinsfile name here, change this value if you are using a 
    different file name 

**Optional parameters:**

::

    $GIT_BASE        - GIT_BASE is a custom jenkins environment variable defined in Jenkins with 
    `gopath/src/github.com/hyperledger/$PROJECT`
    $PROJECT         - PROJECT is a custom jenkins environment variable defined in Jenkins with the 
    project name. ex: fabric-samples
    $GERRIT_REFSPEC  - GERRIT_REFSPEC is a Jenkins environment variable provides the gerrit patchset 
    reference number 

**Global Environment Variables**

See this file for reference
https://github.com/hyperledger/ci-management/blob/master/jenkins-config/global-vars-production.sh

Macros
------

**gerrit-trigger-patch-submitted**

-  This macro triggers a jenkins job when a ``patchset-created-event``
   is triggered
-  Don’t trigger the job when a commit message is updated in the gerrit
   patchset
-  Trigger the jobs when a comment is posted in the gerrit patchset.
   Comments are specified in the job configuration
-  It triggers the job on a branch pattren specified in the job
   configuration

**fabric-pipeline-properties** : This macro provides the below
environment variables in each job type. These variables can be accessed
by ``env.<ParameterName>`` in Jenkinsfile. ex: ``env.JOB_TYPE``

How to create a new pipeline verify job:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The above job template is a common template for any pipeline verify
jobs. Use the below configuration in your project directory under
``jjb`` folder and modify the below parameters based on your project
need. Make sure the jenkins node label and the name of the jenkins_file
are available. NOTE: Don’t modify the ``fab-pipeline-verify`` as it is a
``id`` specified to the pipeline verify job. This ``id`` will be used in
across all the pipeline verify job with pre-configured jenkins job
configuration.

::

    ---
    - project:
        name: fabric-<project_name>-verify-jobs
        jobs:
          - 'fab-pipeline-verify'

        project: <project_name>
        branch: ''
        arch: 'x86_64'
        build_node: 'x'
        job_type: 'verify'
        jenkins_file: Jenkinsfile

The new pipeline verify job configuration will create a new job name as
``fabric-<project_name>-verify-<arch>`` ex:
``fabric-samples-verify-x86_64`` follow this document
https://github.com/hyperledger/ci-management/blob/master/Sandbox_Setup.md
to test the newly created job and push to sandbox for testing. After
your changes and testing is done, push this change to
https://gerrit.hyperledger.org/r/#/admin/projects/ci-management
repository, add reviewers in the patchset and post the same in the
#ci-pipeline RocketChat channel for quick response.

Once your patch is verified and reviewed, the patch will get merged by
CI maintainers and then further it updates in the Production Jenkins
Configuration. https://jenkins.hyperledger.org/

Pipeline Merge Job
~~~~~~~~~~~~~~~~~~

Follow the same approach for the pipeline merge job. All you have to do
is, copy the below code template to your project directory under jjb.

**Template Names:** - ‘{project}-merge-{arch}’

**Names:** - -merge-x86_64

**Merge Template**

::

    - pipeline_merge: &pipeline_merge
        name: pipeline-merge

        project-type: pipeline
        concurrent: true
        pipeline-scm:
          script-path: '{jenkins_file}'
          scm:
            - git:
                credentials-id: 'hyperledger-jobbuilder'
                url: '$GIT_BASE'
                shallow-clone: true
                refspec: +refs/heads/$GERRIT_BRANCH:refs/remotes/origin/$GERRIT_BRANCH'
                wipe-workspace: true
                clean:
                  before: true
                  after: true
                branches:
                  - refs/heads/$GERRIT_BRANCH

        parameters:
          - project-parameter:
              project: '{project}'
          - gerrit-parameter:
              branch: 'master'
          - gerrit-refspec-parameter:
              refspec: 'refs/heads/$GERRIT_BRANCH'

        properties:
          - fabric-pipeline-properties:
              job-type: '{job_type}'
              build-node: 'hyp-{build_node}'
          - build-discarder:
              days-to-keep: 10
              artifact-days-to-keep: 7

        triggers:
          - gerrit-trigger-patch-merged:
              name: '{project}'
              branch: '{branch}'
              trigger-comment1: 'remerge$'
              trigger-comment2: 'remerge-{build_node}$'

    - job-template:
        name: '{project}-merge-{arch}'
        id: fab-pipeline-merge
    <<: *pipeline_merge

.. _macros-1:

Macros
------

**gerrit-trigger-patch-merged**

-  This macro triggers a jenkins job when a ``change-merged-event`` is
   triggered
-  Don’t trigger the job when a commit message is updated in the gerrit
   patchset.
-  Trigger the jobs when a comment is posted in the gerrit patchset.
   Comments are specified in the job configuration.
-  Trigger the job on a branch pattren specified in the job
   configuration.

**Comment Trigger:** - Trigger the verify jobs by posting a comment
phrase ``remerge`` and ``remerge-x`` or ``remerge-z`` etc.. based on the
value you provided to ``build_node``

**Merge Job configuration**

::

    ---
    - project:
        name: fabric-<project_name>-merge-jobs
        jobs:
          - 'fab-pipeline-merge'

        project: <project_name>
        branch: ''
        arch: 'x86_64'
        build_node: 'x'
        job_type: 'merge'
        jenkins_file: Jenkinsfile

See an example here
https://github.com/hyperledger/ci-management/blob/master/jjb/fabric-sdk-node/fabric-sdk-node-jobs.yaml
