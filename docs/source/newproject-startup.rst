
New Project Start Up
--------------------

This section attempts to provide details on how to get going as a new project
quickly with minimal steps. The rest of the guide should be read and understood
by those who need to create and contribute new job types that is not already
covered by the existing job templates provided by hyperledger/ci-management JJB repo.

As a new project you will be mainly interested in getting your jobs to appear
in the jenkins-master silo and this can be achieved by simply creating a
<new-project>.yaml in the hyperledger/ci-management project's jjb directory.

.. code-block:: bash

    git clone ssh://'LF-username'@gerrit.hyperledger.org:29418/ci-management
    cd ci-management
    mkdir jjb/<new-project>

.. note:

hyperledger/global-jjb is a submodule of hyperledger/ci-management repository which
requires a git submodule update --init or using --recursive with git clone
`hyperledger-global-jjb`.

Where <new-project> should be the same name as your project's git repo in
Gerrit. If your project is called "octopus" then create a new jjb/octopus directory.

Next we will create <new-project>.yaml as follows:

.. code-block:: bash

   ├── <new-project>
   │   ├── <new-project>-jobs.yaml
   │   ├── <new-project>-macros.yaml
   │   ├── <new-project>-template.yaml
   │   └── shell
   │       ├── include-raw-testscript.sh

For reference see the tree structure of the fabric-sdk-node.
Replace all instances of <new-project> with the name of your project.
Finally we need to push these files to Gerrit for review by the ci-management
team to push your jobs to Jenkins.

.. code-block:: bash

    git add jjb/<new-project>
    git commit -s "Add <new-project> jobs to Jenkins"
    git push origin HEAD:refs/for/master

This will push the jobs to Gerrit and your jobs will appear in Jenkins once the
ci-management team has reviewed and merged your patch.
