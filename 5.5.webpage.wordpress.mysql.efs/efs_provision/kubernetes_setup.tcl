"-----------------------------------------------------"
"               Global variable                       "
"-----------------------------------------------------"
bucket_name=bucket.chotot.vpc
CHOTOT_DNS_ZONE=chotot.vpc
CHOTOT_CLUSTER_NAME=cluster.chotot.vpc
export KOPS_STATE_STORE=s3://${bucket_name}

# Delete the whole stack
kops delete cluster --name=${CHOTOT_CLUSTER_NAME} --yes


"-----------------------------------------------------"
"   Create S3 bucket for storing state of KOPS        "
"-----------------------------------------------------"
#Create bucket to store state of KOPS
aws s3api create-bucket --bucket ${bucket_name} --create-bucket-configuration LocationConstraint=us-west-2
aws s3api put-bucket-versioning --bucket ${bucket_name} --versioning-configuration Status=Enabled

"-----------------------------------------------------"
"       Deployment cluster using Kubernetes    		  "
"-----------------------------------------------------"
kops create cluster \
--cloud=aws --zones=us-west-2a \
--node-count=3 \
--node-size=t2.micro --master-size=t2.micro \
--dns-zone=${CHOTOT_DNS_ZONE} --dns private \
--name=${CHOTOT_CLUSTER_NAME}

#Actually deploy
kops update cluster --name ${CHOTOT_CLUSTER_NAME} --yes


"-----------------------------------------------------"
"      Create EFS for shared volume (mysql, wp)       "
"-----------------------------------------------------"
aws efs create-file-system --creation-token $(uuid)    
    >>> get "FileSystemID" & "OwnerID"
	
aws efs create-mount-target \
        --file-system-id <FileSystemID> \
        --subnet-id <subnet-id> \
        --security-groups <security-groups>
		
aws efs describe-mount-targets --file-system-id <FileSystemID>
    >>> wait for EFS drive to be available
	
aws ec2 authorize-security-group-ingress --group-id sg-04b62fc4af711d0e3 --protocol tcp --port 2049 --source-group sg-04b62fc4af711d0e3 --group-owner 495627566033	
    >>> authorize traffic on resources of AWS

" Note: second EFS for mysql should be the same action"
	
"-----------------------------------------------------"
"          Using K8S to provision EFS volumes 		  "
"-----------------------------------------------------"

kubectl create -f efs_provision/efs-provisioner-mysql.yaml
kubectl create -f efs_provision/efs-provisioner-wp.yaml	
	
	
	
	
	
	