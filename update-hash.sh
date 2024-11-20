#!/bin/bash

# inputs for the script
DIR_ASSIGNMENT_3=/home/user/EmbeddedLinux/assignment-avt82/
DIR_ASSIGNMENT_YOCTO=/home/user/EmbeddedLinux/yocto-avt82/
EXT_PKG_DIR=${DIR_ASSIGNMENT_YOCTO}meta-aesd/
PKG_NAME=aesd-assignments

# function enters the directory $1 and prints the hash of last commit
function get_hash_git() {
    if [ ! -d "${1}" ] ; then
	return 1
    fi
    cd "${1}"
    git rev-parse HEAD
}

# gets a an argument inside single quotes from a line
function trip_hash() {
    a="${1#*\'}"
    a="${a%\'*}"
    echo ${a}
}

log=

# function reads the file ${1},
# prints it content with altering a line(s) that contains ${2}
# with line ${3}, if the line is not already equals to ${3}
# returns amount of lines updated (no increment if the hash matches)
function cat_file_altered() {
    content=`cat "${1}"`

    ret=0
    OLD_IFS="${IFS}"
    while IFS=""; read -r line ; do
	srch=`echo -en "${line}" | grep "${2}"`
	if [ ! -z "${srch}" ] ; then
	    hash1=`trip_hash "${line}"`
	    hash2=`trip_hash "${3}"`
	    if [ "${hash1}" != "${hash2}" ] ; then
		(( ret++ ))
	    fi
	    line="${3}"
	fi
	echo "${line}"
    done < "${1}"
    IFS="${OLD_IFS}"

    return ${ret}
}

# deletes file $2 if exists
# backups file $1 to $2
function backup_file() {
    if [ -f "${2}" ] ; then
	echo " - Deleting old backup file ${2}..."
	rm ${2} 1>/dev/null 2>/dev/null
    fi
    echo " - Copying ${1} -> ${2}..."
    cp ${1} ${2} 1>/dev/null 2>/dev/null
}

# do all the magic
# $1 - package name
# $2 - git folder with external project to obtain hash from
# returns 0 if file is processed;
#         1 if file already contains correct hash;
#         2 if source file is not found
#         3 if cannot obtain git hash
function process_mk_file() {
    # that's gonna be our package .mk file
    BB_FILE=${EXT_PKG_DIR}recipes-${1}/${1}/${1}_git.bb

    if [ ! -f "${BB_FILE}" ] ; then
	echo "Cannot find file ${BB_FILE}"
	return 2
    fi

    # gets the hash of latest commit by git
    new_hash=`get_hash_git "${2}"`
    if [ -z "${new_hash}" ] ; then
	echo "Cannot obtain git hash from ${2}"
	return 3
    fi

    # uppercase package name, suffixing it with _VERSION;
    # dashes are replaced with underscores
    SEARCH="SRCREV"
    # gets the file with altered string with hash

    new_text=`cat_file_altered "${BB_FILE}" "${SEARCH}" "${SEARCH} = '${new_hash}'"`

    ret=$?
    if (( ret > 0 )) ; then
	backup_file "${BB_FILE}" "${BB_FILE}.old"
	echo " - Replacing file ${BB_FILE}..."
	echo "${new_text}" > "${BB_FILE}"
	return 0
    fi
    echo " - No hash to update in ${BB_FILE}..."
    
    return 1
}

old_dir=`pwd`

process_mk_file "${PKG_NAME}" "${DIR_ASSIGNMENT_3}"

cd ${old_dir}
