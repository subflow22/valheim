---
schemaVersion: '2.2'
description: 'Execute bash scripts stored in S3.'
mainSteps:
- action: aws:downloadContent
  name: downloadContent
  inputs:
    sourceType: "S3"
    sourceInfo: "{\"path\":\"https://s3.amazonaws.com/${BUCKET_NAME}/scripts/valheim_backup.sh\"}"
    destinationPath: "/opt/valheim/"
- precondition:
    StringEquals:
    - platformType
    - Linux
  action: aws:runShellScript
  name: runShellScript
  inputs:
    runCommand:
    - ''
    - sudo chmod 770 /opt/valheim/valheim_backup.sh
    - sudo /opt/valheim/valheim_backup.sh
    - ''
    workingDirectory: "/opt/valheim/"
    timeoutSeconds: "360"