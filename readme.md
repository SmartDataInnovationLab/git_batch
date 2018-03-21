# git batch

This will create a git remote, that takes care of running batch jobs.

The user pushes into the batch-remote to run the batch job and fetches the results by pulling from the batch-remote. The batch job is configurated by the users.


## quickstart

Here is a small example for how to setup up a  remote repository for batch work

```bash
cd $(mktemp -d)
wget https://raw.githubusercontent.com/SmartDataInnovationLab/git_batch/master/init_batch_repo.sh
chmod +x init_batch_repo.sh
./init_batch_repo.sh $HOME/.batch

cd /path/to/my_project
git remote add batch $HOME/.batch/repo.git

#set up your scheduler for this project
nano schedule.sh
git add schedule.sh

# do a test-run
git commit -m "added scheduling for batch processing"
git push batch master

# when batch finishes, get results with
git pull batch master
```

Note: `schedule.sh` must make sure the project is run, and the results are committed.

To undo those changes:

```bash
rm -rf $HOME/.batch
git remote remove batch
```

## table of content

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=3 orderedList=false} -->
<!-- code_chunk_output -->

* [git batch](#git-batch)
	* [quickstart](#quickstart)
	* [table of content](#table-of-content)
	* [examples](#examples)
		* [at_notebook](#at_notebook)
* [dev notes](#dev-notes)
	* [relevant links](#relevant-links)
	* [setting up debugging](#setting-up-debugging)
		* [htcondor inside docker](#htcondor-inside-docker)

<!-- /code_chunk_output -->

## examples

all subfolders of the `examples` folder contain a `schedule.sh` file and  supporting files to set up a runnable project.

### at_notebook

This example project will schedule a job via [at](https://en.wikipedia.org/wiki/At_(Unix)).

To run this example:

```bash
git clone git@github.com:SmartDataInnovationLab/git_batch.git
cd git_batch

# init a bash remote
./init_batch_repo.sh $HOME/.batch

# copy the example project into a empty directory
cp -r examples/at_notebook/ /tmp/at_notebook

# prepare the git repository
git init; git add .; git commit -m "."
git remote add batch $HOME/.batch/repo.git

# do a test run
git push batch master

# look at the log (defined in schedule.sh)
cat /tmp/at.log

# pull the results (the output from "git push" will tell you the exact command)
git pull batch 2018-03-21T143210
```

to actually run the notebook, you might install the python requirements

    pip3 install -r requirements.txt


# dev notes

this section is only relevant, if you want to edit this project

## relevant links

condor:

* https://github.com/andypohl/htcondor-docker
* https://research.cs.wisc.edu/htcondor/manual/quickstart.html
* http://wiki.scc.kit.edu/lsdf/index.php/Developing_a_HTCondor_Plugin_for_Jupyter_Notebook

sdil:

* http://www.sdil.de/system/assets/100/original/sdil-platform-documentation.pdf
* http://www.sdil.de/system/assets/99/original/sdil-platform-tutorials.pdf


git:

* https://www.digitalocean.com/community/tutorials/how-to-use-git-hooks-to-automate-development-and-deployment-tasks
* https://stackoverflow.com/a/32170260/5132456

Leseliste:

* longs demo-notebook
* daniels masterthesis

offene Recherche:

* Wie werden in CI/CD die git modules behandelt?  


## setting up debugging

* (ggf. remote undso einrichten)
* shell1: `tail -f /tmp/at.log`
* shell3: `echo "a" >> a.txt ; git commit -am "." ; git push batch master`


### htcondor inside docker

host starten:

    docker run -it --rm -h htcondor --name htcondor andypohl/htcondor

job starten:

(im sdil ist das nur "condor_submit run.sub")

    docker cp . htcondor:/home/submitter/submit
    docker exec -ti htcondor chown -R 1000:1000 .
    docker exec -ti htcondor chmod +x dummy.py
    docker exec -ti -u 1000:1000 htcondor condor_submit run.sub

job anschauen:

    docker exec -ti -u 1000:1000 htcondor condor_status
    docker exec -ti -u 1000:1000 htcondor cat dummy.log
    docker exec -ti -u 1000:1000 htcondor cat outfile.txt

debugging:

    docker exec -ti -u 1000:1000 htcondor bash
