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

## why git?

We use git to make experiments reproducible. When we check in the code, the conda-environment and softlinks to the data, the experiment becomes reproducible.

After this we "only" need to make sure the data won't get changed, which we do via file-system permissions; And we need to make sure, there are no outside-influences, which is why only run binaries from conda.

As long as you follow the instructions, your computations will be reproducible by others.

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

Note: As of june 2018, git and condor don't seem to work on the same machine at the same time. So this section currently doesn't work on SDIL.

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

```bash
ssh <your_username>@bi-01-login.sdil.kit.edu

#install dirhash
git clone git@github.com:SmartDataInnovationLab/dirhash.git
cd dirhash
mvn package
cd ..

# check out the example-project and
git clone git@github.com:SmartDataInnovationLab/git_batch.git

# copy the example project into an empty directory
cp -r git_batch/examples/condor_dirhash/ condor_dirhash
cd condor_dirhash

# freeze the data in your archive
# first hash the data
HASH=$(../dirhash/run.sh $(pwd)/data/)

# now create a folder for the hashed data
mkdir ../archive
mkdir ../archive/$HASH

# move data to the archive and add softlink to project
mv data ../archive/$HASH/
ln -s ../archive/$HASH/ data

# make archive read-only (to avoid accidental changes)
chmod -R a-w ../archive/$HASH

# as you can see the data-dir is now softlinked to the archive, and inside all the files are readonly
ls -la data data/

# the rest will be done on the login-machine, since the BI machines don't have access to conda
ssh <your_username>@login-l.sdil.kit.edu
cd temp/condor_dirhash/

# prepate a conda environment for your project (now is a good time to grab a coffee. This will take a while)
setup-anaconda
conda create --name=my_env --clone=anaconda-py35 --copy

# tell your run-script to use this environment, so it will be used when executed in htcondor
sed -i -e 's/anaconda-py35/my_env/' run.sh

# install packages to your environment
conda install --name=my_env nbformat numpy matplotlib
conda install --name=my_env -c anaconda git

# tell condor your email adress, so it can notify you when the job is done.
# remove the comment in the line with 'notify_user' and fill in your own email address
nano run.sub

# prepare the git repository
git init && git add . && git commit -m "input for batch job"

# do a test run (we need condor for this, so connect to the correct machine)
condor_submit run.sub

# wait until the job is done
# you can look at it with
condor_q

# look at the log
cat condor_outfile.txt 
cat condor_errors.txt

# checkin results
git add . && git commit -m "result from batch job"
```



## how does it work?

The heart of the project is the receive-hook in the remote repository. Whenever the remote repository receives a pull, it will create a new work tree for the received branch, and then it will call `schedule.sh` from the branch inside the worktree's folder.

The `schedule.sh` is the entry-point for the user-customization. Here the actual scheduling has to initiated (e.g. with a simple "condor_submit").

For the best experience the results should be commited after the job is run (this must be done by a user-supplied script, because the receive-hook can not know when the job is finished). This way the user can access the results with a simple `git pull`

Note: the schedule script runs inside the hook, which means that it will be run as the user doing the push; Its output will be part of the output of `git push`, and it has to finish before `git push` can finish.

Note: we might remove the receive-hook in favor of other CI-Practices in the future

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
