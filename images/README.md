MariaDB Galera Docker Images
----------------------------

Make sure to create an __registry__ file in this folder and put the full name of the target docker repository for the images.

> Note that the entry should not end in a '/', this will be added by the build scripts...

Eg.

docker.example.com/itso/caas/mariadb-galera-docker

Then you can run the __build__ scripts in each image folder to create and push the images to the repository.