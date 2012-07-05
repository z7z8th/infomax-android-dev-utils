[ $(ps -p $$ -o comm=) != "bash" ] && { bash -l; return; }

this_java_ver='6'
this_java_ver_grep='1\.6\.0'
this_java_dir="java-${this_java_ver}-sun"
{ update-alternatives --query java | grep "Value:.*${this_java_dir}"; } && \
    { update-alternatives --query javac | grep "Value:.*${this_java_dir}"; } && \
        { update-alternatives --query javaws | grep "Value:.*${this_java_dir}"; } || \
{
    echo "change java* to $this_java_dir"
    sudo update-alternatives --set java /usr/lib/jvm/${this_java_dir}/jre/bin/java ;
    sudo update-alternatives --set javac /usr/lib/jvm/${this_java_dir}/bin/javac ;
    sudo update-alternatives --set javaws /usr/lib/jvm/${this_java_dir}/jre/bin/javaws ;
}

java -version 2>&1 | grep "^java version \"${this_java_ver_grep}" || { echo -e "**** ERROR **** \nneed java version $this_java_ver_grep"; return 1; }
javac -version 2>&1 | grep "^javac ${this_java_ver_grep}" || { echo -e "**** ERROR **** \nneed javac $this_java_ver_grep"; return 1; }


#### configs below is not portable, do *not* copy directly ####
export JAVA_HOME=/usr/lib/jvm/${this_java_dir}
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:$CLASSPATH 
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
export ANDROID_JAVA_HOME=$JAVA_HOME

export USE_CCACHE=1
export CCACHE_DIR=/opt2/ccache
export MAKEFLAGS='-j4'

export PATH=$PATH:$(pwd)/out/host/linux-x86/bin

source build/envsetup_infomax.sh
