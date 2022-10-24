#!/bin/bash
expiring_time=48
is_recursive=0
temp_file_paths="temp_file_paths.txt"

while getopts ":rt:" opt; do
    case "${opt}" in
        r)
            is_recursive=1
            ;;
        t)
            expiring_time=${OPTARG}
            ;;
        *)
            echo "Usage: freespace [-r] [-t ###] file [file...]"
            ;;
    esac
done
shift $((OPTIND-1))


get_files()
{

    local path=$1

    if [[ $is_recursive -eq 1 ]]
    then 
        # Recursively retrieves
        find $path -type f > $temp_file_paths
    else
        # Recursively retrieves
        find $path -maxdepth 1 -type f > $temp_file_paths
    fi
}


zip_files()
{
    path=$1

    description="$(file $path)"

    # convert to lower case
    description="${description,,}"

    basename="$(basename $path)"
    dirname="$(dirname $path)"

    # remove extension
    basename=${basename%.*}
    new_file_path="$dirname/fc-$basename.zip"


    if [[ $description =~ "bzip2" ]]
    then

        if [[ $basename =~ "fc-" ]]
        then
            delete_zip_file $path
        else
            # modify file date
            mv $path new_file_path
            touch $new_file_path
        fi

    elif [[ $description =~ "zip" ]]
    then
        if [[ $basename =~ "fc-" ]]
        then
            delete_zip_file $path
        else
            # modify file date
            mv $path new_file_path
            touch $new_file_path
        fi


    elif [[ $description =~ "gzip" ]]
    then
        if [[ $basename =~ "fc-" ]]
        then
            delete_zip_file $path
        else
            # modify file date
            mv $path new_file_path
            touch $new_file_path
        fi

    else

        # zip file to new file name
        zip $new_file_path $path
        
        # remove non zip file
        rm -rf $path
    fi
}


delete_zip_file()
{
    # Delete ziped file
    # which time is greater
    # than expiry time
    path=$1
    current_timestamp=$(date +%s)
    file_modify_timestamp=$(stat -c '%Y' $path)

    time_in_second=$(($current_timestamp - $file_modify_timestamp))
    time_in_minute=$(($time_in_second / 60))
    time_in_hour=$(($time_in_minute / 60))

    # delete file when expiring time is due
    if [[ $time_in_minute -ge $expiring_time ]]
    then
        rm -rf $path
    fi

}



# Loop over all 
# args pass to script
for path in "$@"
do
    if [[ -f  $path ]]
    then
        zip_files $path

    else
        # retrieve all files
        # and it in temp file
        get_files $path


        # load file from
        # temp file and zip
        while read -r path; do
            zip_files $path
        done <$temp_file_paths 
    fi
done


# remove temp_file_paths.txt
rm -rf $temp_file_paths






