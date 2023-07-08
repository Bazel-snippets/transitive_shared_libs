#!/usr/bin/env bash
set -euo pipefail

##############################################################
# The canonical home of this script is:
#   https://gitlab.tableausoftware.com/tableaubuild/bazel/bootstrapper/-/blob/main/src/bazel.sh
#
# Do not edit it anywhere else.
#
# If you want to consume it in a new location, talk to dpe-codex-buildsys about adding your usage to deploy.py
##############################################################

self=`basename "$0"`

currentArch=$(uname -m)

ensureHaveBazel()
{
    bazelVersion=`cat $(dirname "$BASH_SOURCE")/.bazelversion | tr -d '\r'`
    bazelCacheDirectory=`echo ~/.cache/tabbazel`

    # Note that old JDKs in the cache will not get garbage collected, and will
    # continue to be noticed by security scans. When you change the JDK version,
    # consider taking some step to mitigate that, such as notifying users or
    # adding a step to delete unpatched JDKs in the cache.
    #
    # These paths come from https://swarm.tsi.lan/files/depot/teams/near/tableau-support/java/java.properties
    if [[ "$OSTYPE" == "darwin"* ]]
    then
        if [[ "$currentArch" == "x86_64" ]]
        then
            bazelJdkArtifactoryUrl="thirdparty/openjdk/azul/11.0.14/zulu11.54.26-sa-jdk+jre11.0.14-osx_x64.tar.gz"
        else
            bazelJdkArtifactoryUrl="thirdparty/openjdk/azul/11.0.19/zulu11.64.19-ca-jdk11.0.19-macosx_aarch64.tar.gz"
        fi
    else
        bazelJdkArtifactoryUrl="thirdparty/openjdk/azul/11.0.14/zulu11.54.26-sa-jdk+jre11.0.14-linux_x64-sfdc.3-tableau.tar.gz"
    fi
    bazelJdkPackageName=$( basename $bazelJdkArtifactoryUrl .tar.gz )
    export JAVA_HOME=$bazelCacheDirectory/jdk/$bazelJdkPackageName/

    mkdir -p $bazelCacheDirectory/$bazelVersion-$currentArch
    bazelBinaryPath=$bazelCacheDirectory/$bazelVersion-$currentArch/bazel

    if [ ! -f $bazelBinaryPath ]
    then
        runHealthChecks
        downloadBazel
    fi

    if [ ! -d $JAVA_HOME ]
    then
        downloadJdk
    fi
}

runHealthChecks()
{
    echo "${self}: running machine health checks" 1>&2
    dir="$(dirname "$BASH_SOURCE")/bazel/bootstrapper_health_checks/"
    if [ -d ${dir} ]
    then
        find ${dir} -name "*.sh" -type f -print0 | xargs -0 -n1 sh
    fi
}

downloadBazel()
{
    if [[ "$OSTYPE" == "darwin"* ]]
    then
        operatingSystem="darwin"
    else
        operatingSystem="linux"
    fi

    # Release candidates are published to a different location than prerelease and full release, and so are not cached in Artifactory
    if [[ $bazelVersion == *rc* ]]
    then
        url="https://releases.bazel.build/${bazelVersion%%rc*}/rc${bazelVersion#*"rc"}/bazel_nojdk-$bazelVersion-$operatingSystem-${currentArch}"
    else
        url="https://artifactory.prod.tableautools.com/artifactory/bazel-releases-remote/download/$bazelVersion/bazel_nojdk-$bazelVersion-$operatingSystem-${currentArch}"
    fi

    echo "${self}: Downloading bazel binary from '$url' to '$bazelBinaryPath'" 1>&2
    outputFile=`mktemp -u`
    curl --fail --location --output $outputFile $url 1>&2
    mv $outputFile $bazelBinaryPath
    chmod +x $bazelBinaryPath
}

downloadJdk()
{
    url="https://artifactory.prod.tableautools.com/artifactory/$bazelJdkArtifactoryUrl"

    echo "${self}: Downloading JDK from '$url' to '$JAVA_HOME'" 1>&2
    outputFile=`mktemp -u`.tar.gz
    curl --fail --silent --location --output $outputFile $url
    mkdir -p $bazelCacheDirectory/jdk
    tar -xzf $outputFile -C $bazelCacheDirectory/jdk
    if [ ! -d $JAVA_HOME ]
    then
        echo "JDK not found at $JAVA_HOME" 1>&2
        exit 1
    fi
}

ensureHaveBazel
cd "$(dirname "$BASH_SOURCE")"
$bazelBinaryPath $*
