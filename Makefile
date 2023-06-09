

init:
	terraform init

validate: 
	terraform validate

readme:
	docker run --rm --volume "$$(pwd):/terraform-docs" -u $$(id -u) quay.io/terraform-docs/terraform-docs:0.16.0 markdown /terraform-docs > README.md 