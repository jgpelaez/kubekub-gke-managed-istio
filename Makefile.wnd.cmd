@ECHO off   

set GO111MODULE=on
goto %1

:login
gcloud auth application-default login
goto :eof

:cluster-data
pulumi config set nodeMachineType n1-standard-1
pulumi config set nodeCount 3
pulumi config set password --secret adminadminadminadmin
pulumi config set gcp:zone europe-west1-b
gcloud container clusters get-credentials standard-cluster-1 --zone us-central1-a --project qwiklabs-gcp-76445b7300a5c101
goto :eof