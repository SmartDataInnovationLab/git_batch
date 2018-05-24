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
		* [htcondor notebook](#htcondor-notebook)
	* [how does it work?](#how-does-it-work)
* [dev notes](#dev-notes)
	* [relevant links](#relevant-links)
	* [setting up debugging](#setting-up-debugging)
		* [htcondor inside docker](#htcondor-inside-docker)

<!-- /code_chunk_output -->

## examples

all subfolders of the `examples` folder contain a `schedule.sh` file and  supporting files to set up a runnable project.

### at_notebook

This example project will schedule a job via [at](https://en.wikipedia.org/wiki/At_(Unix)).

To run this example from scratch:

```bash
git clone git@github.com:SmartDataInnovationLab/git_batch.git

# init a batch remote
./git_batch/init_batch_repo.sh $HOME/.batch

# copy the example project into an empty directory
cp -r git_batch/examples/at_notebook/ /tmp/at_notebook
cd /tmp/at_notebook

# prepare the git repository
git init; git add .; git commit -m "."
git remote add batch $HOME/.batch/repo.git

# do a test run
git push batch master

# wait until the job is done
sleep 5

# look at the log (defined in schedule.sh)
cat /tmp/at.log

# pull the results
git pull batch master
```

to actually run the notebook, you might install the python requirements

    pip3 install -r requirements.txt

### htcondor notebook

This example shows how to setup and run notebooks remotely on sdil via condor.

first setup a remote repository on sdil:

```bash
ssh <your_username>@login-l.sdil.kit.edu
cd $(mktemp -d)
wget https://raw.githubusercontent.com/SmartDataInnovationLab/git_batch/master/init_batch_repo.sh
chmod +x init_batch_repo.sh
./init_batch_repo.sh $HOME/.batch
```

then copy the example onto your local machine and try it out

```bash
git clone git@github.com:SmartDataInnovationLab/git_batch.git

# copy the example project into an empty directory
cp -r git_batch/examples/condor_notebook/ /tmp/condor_notebook
cd /tmp/condor_notebook

# optional: update path to git in run.sh, because htcondor runs as a different user and may not know the correct version of git
nano run.sh

# prepare the git repository
chmod +x schedule.sh
git init; git add .; git commit -m "."
git remote add batch ssh://<your_username>@login-l.sdil.kit.edu/smartdata/<your_username>/.batch/repo.git

# do a test run
git push batch master

# wait until the job is done
sleep 10

# pull the results
git pull batch master

# look at the log
cat condor_log.txt
```

### condor and dirhash

this example is the same as above, except the data will be frozen in a hashed archive 

Setup your remote like you did above, except this time do it on the bi-cluster (because we need pyspark): 

```bash
ssh <your_username>@bi-01-login.sdil.kit.edu
cd $(mktemp -d)
wget https://raw.githubusercontent.com/SmartDataInnovationLab/git_batch/master/init_batch_repo.sh
chmod +x init_batch_repo.sh
./init_batch_repo.sh $HOME/.batch
```

now check out the example-project and 

```bash
git clone git@github.com:SmartDataInnovationLab/git_batch.git

# copy the example project into an empty directory
cp -r git_batch/examples/condor_dirhash/ $HOME/temp/condor_dirhash
cd $HOME/temp/condor_dirhash

# freeze the data in your archive 
pyspark --jars $HOME/dev/dirhash/target/sparkhacks-0.0.1-SNAPSHOT.jar $HOME/dev/dirhash/dirhash.py $HOME/temp/condor_dirhash/data/ --move-to-archive $HOME/temp/archive/ --softlink $HOME/temp/condor_dirhash/data/ 2>/dev/null

# optional: update path to git in run.sh, because htcondor runs as a different user and may not know the correct version of git
nano run.sh

# prepare the git repository
chmod +x schedule.sh
git init; git add .; git commit -m "."
git remote add batch $HOME/.batch/repo.git

# do a test run (we need condor for this, so connect to the correct machine)
ssh <your_username>@login-l.sdil.kit.edu
cd $HOME/temp/condor_dirhash
git push batch master

# wait until the job is done
sleep 10

# pull the results
git pull batch master

# look at the log
cat condor_log.txt
```



## how does it work?

The heart of the project is the receive-hook in the remote repository. Whenever the remote repository receives a pull, it will create a new work tree for the received branch, and then it will call `schedule.sh` from the branch inside the worktree's folder.

The `schedule.sh` is the entry-point for the user-customization. Here the actual scheduling has to initiated (e.g. with a simple "condor_submit").

For the best experience the results should be commited after the job is run (this must be done by a user-supplied script, because the receive-hook can not know when the job is finished). This way the user can access the results with a simple `git pull`

Note: the schedule script runs inside the hook, which means that it will be run as the user doing the push; Its output will be part of the output of `git push`, and it has to finish before `git push` can finish.

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
