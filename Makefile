ENVIRONMENT = "dev"


usage:
	@echo "Command : make <function> ENVIRONMENT=dev"
	@echo "Example Command : make tf.vpc-setup ENVIRONMENT=dev"
	@echo "tf.vpc-setup : Setup Terraform vpc setup"
	@echo "tf.eks-setup : Setup Terraform eks setup"
	@echo "tf.helm-setup : Setup Terraform helm setup"
	
	@echo "tf.vpc-clean : Delete Terraform vpc"
	@echo "tf.eks-clean : Delete Terraform eks"
	@echo "tf.helm-clean : Delete Terraform helm"
	@echo "tf.all-setup : Setup Terraform VPC -> EKS -> HELM "
	@echo "tf.all-clean : Delete Terraform HELM -> EKS -> VPC"

	@echo "helmfile.apply : Apply helmfile ENV"
	@echo "helmfile.template : Template helmfile"

tf.vpc-setup:
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} apply -auto-approve

tf.eks-setup:
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} apply -auto-approve

tf.helm-setup:
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} apply -auto-approve

tf.vpc-clean:
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} destroy -auto-approve

tf.eks-clean:
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} destroy -auto-approve

tf.helm-clean:
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} destroy -auto-approve
	
tf.all-setup:
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} apply -auto-approve
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} apply -auto-approve
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} apply -auto-approve

tf.all-clean:
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-helm-${ENVIRONMENT} destroy -auto-approve
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/eks-${ENVIRONMENT} destroy -auto-approve
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} init
	@terraform -chdir=terraform/${ENVIRONMENT}/vpc-${ENVIRONMENT} destroy -auto-approve

helmfile.apply:
	@helmfile apply --file helmfile/helmfile.yaml -e ${ENVIRONMENT} -i

helmfile.template:
	@helmfile template --file helmfile/helmfile.yaml -e ${ENVIRONMENT} -init

helm.deploy:
	@helm upgrade --install sock-shop helm-chart/sock-shop --set ingress.host="sock-shop-dev.elesangwon.com",ingress.name="sock-shop-ingress" --create-namespace -n sock-shop
	@helm upgrade --install msa helm-chart/sock-shop --set ingress.host="msa-dev.elesangwon.com",ingress.name="msa-ingress" --create-namespace -n msa
	@helm upgrade --install example helm-chart/sock-shop --set ingress.host="example-dev.elesangwon.com",ingress.name="example-ingress" --create-namespace -n example
	