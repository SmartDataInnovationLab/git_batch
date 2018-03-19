
# git batch

## abstract

This will create a git remote, that takes care of running batch jobs.

The user pushes into the batch-remote to run the batch job and fetches the results by pulling from the batch-remote. The batch job is configurated by the users by supplying a snake file.


## getting started

```bash
cd <project>
git submodule add git@github.com:SmartDataInnovationLab/git_batch.git .batch
pip3 install -r .batch/requirements.txt  --user
./.batch/init_condor_repo.sh <batch-base folder>
cp .batch/examples/dummy.rules snake.rules

# do a test-run
echo "a" >> a.txt ; git commit -am "." ; git push batch

# when condor finishes, get results with
git pull batch
```

## toc

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=3 orderedList=false} -->
<!-- code_chunk_output -->

* [condor hooks](#condor-hooks)
	* [abstract](#abstract)
	* [getting started](#getting-started)
	* [toc](#toc)
		* [relevant links](#relevant-links)
	* [general idea](#general-idea)
		* [use-case](#use-case)
		* [directory-structur](#directory-structur)
* [dev note](#dev-note)
	* [setting up debugging](#setting-up-debugging)
	* [implementation](#implementation)
		* [todo](#todo)
		* [git hooks](#git-hooks)
		* [how to](#how-to)

<!-- /code_chunk_output -->

## general idea

### use-case

  * easy to invoke execution of ipyn on htcondor
  * perfect reproduction

**what user needs to know**

  * invokation: user makes `git push condor master` and hooks and scripts take care of the rest
  * reproduction:
    * data is tagged (dirname = hash of content)
    * data-tag is used in softlink in code-dir
    * code is tagged (git tag or commit hash)
    * --> checking out the `git tag` will give you everything you need to reproduce

**limitations**

Only needs to work inside the user-repo. Especially the big data-files are located in the userrepo.

But it must be considered, that multiple condor-jobs might access the data, while the user is working on it herself.
So there must be some kind of seperation of the files happen.


### directory-structur

  * `~/<projectname>/data`: links (softlinks or hardlink) to outside of repo
    * lots of data
    * some of it readonly and immutable
    * some of it outputdata (needs to be writable)  
  * `~/<projectname>/condor`: submodule
    * `init_repo.sh`: create repo to push into
    * `post-receive`: git-hook, creates worktree, invokes condor_submit for `condor.run`
    * `condor.run`: job file for htcondor. invokes `condor.sh`
    * `condor.sh`: invokes `pre_run`, `run` and `post_run`
    * `pre_run.sh`: setting up data before running the main script
    * `run.sh`: runs the actual program/notebook/script
    * `post_run.sh`: tagging data and commiting results

#### `~/<projectname>/data`

**Problem:**

* Many runs will produced many duplicate files
* files, that are only read, shall not be copied

**Solution 1**

* git-like hashing of data

(problem: how to handle changes of files?)

**Solution 2**

* using hardlinks to files:
  * New files are created somewhere, filename contains hash of content
  * Old files are never modified
  * when copying into a new dir, only hardlinks are created

**Solution 3**

* Copy on write

How?

* filesystem-level?
* access/write files only via magic?
* replace write-calls in python before executing it?


**Solution 4:**

* everything is read-only
* User must define exception explicitly
* the exceptions will be copied instead of linked

**solution 5:**

* copy everything
* only check in, what was actually changed


**implementation 1**

`%smartcopy`: magic in ipyn, that sets up data

**implementation 2**

`pre_run.sh`: copies files, that are soft-linked and writeable
`post_run.sh`: tags modified files and creates softlinks in worktree

**implementation 2a**

`pre_run.sh`: all links are read-only
`post_run.sh`: tags new files and creates softlinks in worktree

**implementation 3**

user must take care themselves. all input must be readonly. all links outside the repo must be readonly

# dev notes

this section is only relevant, if you want to edit this project

### relevant links

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
* shell1: `tail -f /tmp/mycondor_simulator.log`
* shell2: `tail -f /tmp/mycondor_simulator.log.err`
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
