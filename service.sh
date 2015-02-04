#!/bin/bash
THIS_VERSION="20150205_0011"
THIS_CMD=$(basename $0)

CYG_RUNSRV=cygrunsrv

show_version(){
	echo "${THIS_CMD}, v${THIS_VERSION}, a command wrapper for ${CYG_RUNSRV}"
	return 0
}
do_linux_service_help(){	#1: show_header
	[ -n "$1" ] && show_version
cat << EOF
    --status-all		list info of all cygwin services
    svc_name s|start		start service <svc_name>
    svc_name S|stop		stop service <svc_name>
    svc_name r|restart		restart service <svc_name>
    svc_name st|status		list service <svc_name> status
    svc_name i|install		install service <svc_name>
    svc_name R|remove		remove service <svc_name>

    examples:
        service sshd start
        service xinetd S
EOF
}
do_help(){
	show_version
cat <<EOF
    -h, --help			show help
    -v, --version		show this ${CYG_RUNSRV} wrapper version
1.${CYG_RUNSRV} style commands(extened)
    -H, --HELP			show ${CYG_RUNSRV} help
    -V, --VERSION		show ${CYG_RUNSRV} version.
	
    -S,--START svc_name		start service <svc_name>
    -E,--END svc_name		stop service <svc_name>
    -L,--LIST			list cygwin service names
    -Q,--QUERY svc_name		query service <svc_name> status
    -I,--INSTALL svc_name	install service <svc_name>
    -R,--REMOVE svc_name	remove service <svc_name> if confirmed
    -FR,--FORCE-REMOVE svc_name	remove service <svc_name> directly
2.
    ls [-l] [svc_name]
        svc_name		list service <svc_name>, otherwise all services when not given
        -l			list detail service info
    ll [svc_name]		alias for ls -l [svc_name]
3. linux 'service' style
EOF
	do_linux_service_help
	exit 0
}
do_remove_service(){
    local svc="$1"; local force_rm="$2"
    if [ -z "${svc}" ];then
        echo "please specify the service name you want to remove!"
        exit 1
    fi
    if [ -z "${force_rm}" ];then
        read -p "Remove service ${svc}? (yes/no)" user_ans
        [ "${user_ans}" != "yes" ] && exit 0
    fi
    ${CYG_RUNSRV} -R "${svc}"
    RET=$?
    if [ ${RET} -eq 0 ];then
        echo "service ${svc} removed."
        exit 0
    fi
    echo "remove service ${svc} failed with code ${RET}"
    exit ${RET}
}
do_list_service(){
    local is_full_ls=0
    if [ "$1" == "-l" ];then shift; is_full_ls=1; fi
	local svc="$1"
	if [ -z "${svc}" ];then
		if [ ${is_full_ls} -eq 1 ];then
			${CYG_RUNSRV} --list --verbose
			RET=$?
		else
			${CYG_RUNSRV} --list
			RET=$?
		fi
	else
		if [ ${is_full_ls} -eq 1 ];then
			${CYG_RUNSRV} --query "${svc}" --verbose
			RET=$?
		else
			${CYG_RUNSRV} --query "${svc}"
			RET=$?
		fi
	fi
	exit ${RET}
}

log_helper(){
	local s_action="$1"; local res=$2;
	local no_log_when_ok="$3"; local do_return="$4"
	[ -z "${do_return}" ] && do_return=exit
	if [ ${res} -eq 0 ];then
		[ -z "${no_log_when_ok}" ] &&
			echo "${s_action} successfully."
		${do_return} 0
	fi
	echo "${s_action} failed with code ${res}"
	${do_return} ${res}
}
do_linux_service_cmd(){
	[ "$1" == "--status-all" ] && do_list_service -l
	local svc="$1"; local cmd="$2"
	if [ $# -lt 2 -o  -z "${svc}" -o -z "${cmd}" ];then do_linux_service_help; exit 0; fi
	case "${cmd}" in
	s|start)
		${CYG_RUNSRV} -S "${svc}";
		log_helper "start service ${svc}" $?;;
	S|stop)
		${CYG_RUNSRV} -E "${svc}";
		log_helper "stop service ${svc}" $?;;
	r|restart)
		${CYG_RUNSRV} -E "${svc}";
		log_helper "stop service ${svc}" $? "" "return";
		${CYG_RUNSRV} -S "${svc}";
		log_helper "start service ${svc}" $?;;
	st|status)
		${CYG_RUNSRV} --query "${svc}" --verbose; 
		log_helper "query service ${svc} status" $? no_log_when_ok;;
	i|install)
		${CYG_RUNSRV} -S "${svc}";
		log_helper "install service ${svc}" $?;;
	R|remove) do_remove_service "${svc}";;
	esac
	do_linux_service_help show_ver
	exit 0
}

if [ $# -gt 0 ];then
    case "$1" in
	-h) do_linux_service_help; exit 0;;
	--help) do_help;;
	-v|--version) show_version; exit;;
	-H|--HELP) ${CYG_RUNSRV} --help; exit 0;;
	-V|--VERSION) ${CYG_RUNSRV} --version; exit 0;;
	
    -S|--START|-E|--END|-I|--INSTALL|-L|--LIST|-Q|--QUERY)
        cmd=${1:2:1}; shift
        ${CYG_RUNSRV} -${cmd} $*
        exit $?;;
    -R|--REMOVE) do_remove_service "$2"; exit $?;;
    -FR|--FORCE-REMOVE) do_remove_service "$2" force_remove; exit $?;;
     
     ls) shift; do_list_service $*;;
     ll) shift; do_list_service -l $*;;
	 
	 *) do_linux_service_cmd $*;;
    esac
fi

do_help;

