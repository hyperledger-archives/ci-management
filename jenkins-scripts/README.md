To utilize this directory structure your jenkins instances need to execute the
following startup

```bash
#!/bin/bash
git clone https://gerrit.hyperledger.org/r/ci-management.git /ci-management
/ci-management/jenkins-scripts/init_script.sh
```
