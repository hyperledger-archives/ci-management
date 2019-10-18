.. _ci-management:

Hyperledger ci-management's documentation
==========================================

Summary
^^^^^^^
Welcome to the Hyperledger Fabric community!
The Hyperledger Fabric (and associated) projects use various tools and workflows for the
continuous project development.This documentation will assist you in using these tools and
understanding the workflow(s) for our contributors while working with the Fabric CI infrastructure.

Finding Help on Hyperledger CI
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
We are excited that you want to contribute to the Continuous Integration/Release Engineering
efforts. You're in the right place to get started.If you need additional assistance, we encourage
you to engage with our CI contributors via the following channels:

    - #ci-pipeline channel on Rocket.Chat (For general continuous integration discussions)
      https://chat.hyperledger.org/channel/ci-pipeline

    - #fabric-ci channel on Rocket.Chat (For fabric continuous integration discussions)
      https://chat.hyperledger.org/channel/fabric-ci

    - #infra-support channel on Rocket.Chat (For general infrastructure discussions)
      https://chat.hyperledger.org/channel/infra-support

    - Send an email to the fabric@lists.hyperledger.org mailing list

    - Contact helpdesk@hyperledger.org for any infrastructure support

Common Job Types
^^^^^^^^^^^^^^^^
There are several Jenkins job types that are common across most Hyperledger Fabric projects.
In some cases, you may or may not see all the common job types in every project.

Let's have a look at the common job types.

Verify Jobs
^^^^^^^^^^^
Verify jobs get triggered on every "patchset-created-event". This happens when a patchset is
submitted to Gerrit. All verify jobs will depend on the patchset's parent commit (not the latest
commit of the repo) and patchset commit. Developers have to rebase their patchset to build it on
the latest commit of the repo. A verify job can also be triggered from Gerrit by posting a comment
in the patchset. Every verify job has a unique trigger comment for that job.

Merge Jobs
^^^^^^^^^^
Merge jobs get triggered on a “change-merged-event” event. This happens when a patchset is merged
in Gerrit repo. In all the merge jobs, Jenkins clones the latest code and performs the tests unlike
verify jobs. Just like verify jobs, merge jobs can also be retriggered from Gerrit by posting a
comment to trigger a specific merge job.

Release Jobs
^^^^^^^^^^^^
Release jobs get triggered on a “ref-updated-event” event. This happens when a release tag is
created in the repository. Release jobs publish docker images, binaries and npm modules. These can
be triggered from Gerrit by posting the specific comment for the job.

For more information regarding the release process, you can refer the Release Process Document.
# `TODO <https://gerrit.hyperledger.org/r/#/c/20307/22/docs/source/Release_Process.rst>`

Supported Architectures
^^^^^^^^^^^^^^^^^^^^^^^
Jenkins jobs are broken down further to build, test, and release the Hyperledger
Fabric projects with support for varying CPU architectures. These include:

    - x86_x64 (Open stack minions)
    - s390x

Supported test types
^^^^^^^^^^^^^^^^^^^^^
Additionally with most job types, you will notice the Jenkins jobs are further isolated to include
a number of test types. Those include:

    - End-to-End tests (java sdk e2e, node sdk e2e)
    - BYFN tests (fabca-samples, byfn, eyfn with default, custom channels,
      couchdb, node lang chaincode)
    - Unit tests (linter, spelling, license etc..)
    - Smoke/Functional/Performance/Release tests ( More functional tests from fabric-test repository)
    - Multihost tests

Writing Jenkins Job Definitions using Jenkins Job Builder
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
CI involves the creation and modification of Jenkins job definitions using JJB. To get a better
understanding of how to write Jenkins job definitions, start with reading through the JJB Job
definitions documentation. ## Sandbox_Setup

Contributing to Fabric CI
^^^^^^^^^^^^^^^^^^^^^^^^^
Contributing to the Fabric CI process starts with identifying tasks to work on, and bugs to be
fixed. These items can be found in the JIRA site provided by the Hyperledger Community.
To narrow down tasks and bugs that are directly related to Fabric CI, use the following URLs:

https://jira.hyperledger.org/issues/?filter=11500

.. note::
   If you have questions not addressed by this documentation, or run into issues with any of
   build jobs, please post your question in https://chat.hyperledger.org/channel/ci-pipeline or
   https://chat.hyperledger.org/channel/fabric-ci channels.

.. toctree::
   :maxdepth: 2
   :caption: CI Process

   source/pipeline_jobs
   source/global_macros
   source/newproject-startup
   source/fabric_ci_process
   source/fabric_baseimage
   source/fabric_sdk_node_process
   source/fabric_sdk_java_process

.. TODO Add all needed topics
