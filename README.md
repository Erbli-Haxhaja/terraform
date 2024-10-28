Why do we need Terraform Cloud (or another backend) when we use CI/CD?

Even if we use CI/CD, Terraform comes in handy for other things.

If we have a pipeline which does the same things as for example the terraform code in this repository, multiple runs of the pipeline can try to create multiple instances or resources, which at the end are the same (as defined in the pipeline) and this can create conflicts or not work at all. All this does not happen when terraform is used, because it manages the already created resources and does not create duplicates or does not run into errors when ran again.
Or for example the terraform configuration can be changed and other sections added and when ran again, it does not run into errors in the sections which were already created in a previous run.

Terraform also ensures the configuration is centralized and in one file, which can later be used for other pipelines or by other users.

Multiple pipelines can run the same terraform file and terraform will manage conflicts of these same resources.

Terraform is also good because it integrates very well with other tools and keeps the resource management code in one file, while the other tools do the rest.