#! /bin/sh

function csvSearch(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvSearch "item1=value1" "item2=value2" ... {filename|-}'
		echo 'Search records pointed by items from filename or stdin(-) to stdout.'
		return 0
	fi

	TAB=`echo -n -e "\t"`
	cmd=""
	while [ "$#" != "0" ]
	do
		str=`echo "$1" | sed -e 's/"/\\\\"/g'`
		if [ "$#" = "1" ]
		then
			if [ "X${str}" = "X-" ]
			then
				:
			else
				cmd="cat ${str}|${cmd}"
			fi
		else
			if [ "X${cmd}" = "X" ]
			then
				cmd="egrep \"^${str}${TAB}|^${str}$|${TAB}${str}${TAB}|${TAB}${str}$\""
			else
				cmd="${cmd}|egrep \"^${str}${TAB}|^${str}$|${TAB}${str}${TAB}|${TAB}${str}$\""
			fi
		fi
		shift
	done

	eval "${cmd}"
}

function csvAppend(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvAppend [-s] "item1=value1" "item2=value2" ... {filename|-}'
		echo 'Append a record into filename. If filename is -, read stdin and append a record into it and output to stdout.'
		echo '  -s    Output should be sorted.'
		return 0
	fi

	TAB=`echo -n -e "\t"`; export TAB
	tmpfile1=/tmp/csvutil.${RND}.$$.1.tmp
	sortSw=off
	rec=""
	outf=""
	while [ "$#" != "0" ]
	do
		str=`echo "$1" | sed -e 's/"/\\"/g'`
		if [ "$#" = "1" ]
		then
			outf="${str}"
		else
			if [ "X${str}" = "X-s" ]
			then
				sortSw=on
			else
				if [ "X${rec}" = "X" ]
				then
					rec="${str}"
				else
					rec="${rec}${TAB}${str}"
				fi
			fi
		fi
		shift
	done

	if [ "X${outf}" = "X-"  ]
	then
		if [ "X${sortSw}" = "Xon" ]
		then
			(
				cat
				echo "${rec}"
			) | sort
		else
			cat
			echo "${rec}"
		fi
	else
		if [ "X${sortSw}" = "Xon" ]
		then
			(
				cat ${outf}
				echo "${rec}"
			) | sort >${tmpfile1}
			mv -f ${tmpfile1} ${outf}
		else
			echo "${rec}" >>${outf}
		fi
	fi
}

function csvDelete(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvDelete "item1=value1" "item2=value2" ... {filename|-}'
		echo 'Delete records pointed by items from filename. If filename is -, read stdin and delete records from it and output to stdout.'
		return 0
	fi

	TAB=`echo -n -e "\t"`
	LF=`echo -n -e "\n"`
	RND=${RANDOM}
	tmpfile1=""
	tmpfile2=/tmp/csvutil.${RND}.$$.2.tmp
	file=""
	cmd=""
	while [ "$#" != "0" ]
	do
		str=`echo "$1" | sed -e 's/"/\\\\"/g'`
		if [ "$#" = "1" ]
		then
			if [ "X${str}" = "X-" ]
			then
				tmpfile1=/tmp/csvutil.${RND}.$$.1.tmp
				cat >${tmpfile1}
				cmd="cat ${tmpfile1}|${cmd}"
			else
				file=${str}
				cmd="cat ${str}|${cmd}"
			fi
		else
			if [ "X${cmd}" = "X" ]
			then
				cmd="egrep \"^${str}${TAB}|^${str}$|${TAB}${str}${TAB}|${TAB}${str}$\""
			else
				cmd="${cmd}|egrep \"^${str}${TAB}|^${str}$|${TAB}${str}${TAB}|${TAB}${str}$\""
			fi
		fi
		shift
	done

	if [ "X${tmpfile1}" = "X" ]
	then
		eval "${cmd}" | join -t "${LF}"  -1 1 -2 1 -v 1 ${file} - >${tmpfile2} && mv -f ${tmpfile2} ${file}
	else
		eval "${cmd}" | join -t "${LF}"  -1 1 -2 1 -v 1 ${tmpfile1} -
		rm -f ${tmpfile1}
	fi
}

function csvUpdate(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvUpdate [-s] "item1=value1" "item2=value2" ... -d "item3=value3" "item4=value4" ... {filename|-}'
		echo 'Update records pointed by items in filename. If filename is -, read stdin and update records from it and output to stdout.'
		echo '  -s                    force to sort input before update.'
		echo '  -d "item=value"       "item=value" before -d are keys point records to update.'
		echo '                        "item=value" after -d are new values.'
		echo 'Caution: Input records must be sorted and output is always sorted.'
		return 0
	fi

	TAB=`echo -n -e "\t"`
	LF=`echo -n -e "\n"`
	RND=${RANDOM}
	tmpfile1=""
	tmpfile2=/tmp/csvutil.${RND}.$$.2.tmp	# 更新対象データ
	tmpfile3=/tmp/csvutil.${RND}.$$.3.tmp	# 更新対象外データ	
	tmpfile4=/tmp/csvutil.${RND}.$$.4.tmp	# 更新対象データを１項目１行に分解
	tmpfile5=/tmp/csvutil.${RND}.$$.5.tmp	# 更新トランザクションを１項目１行に分解
	tmpfile6=/tmp/csvutil.${RND}.$$.6.tmp	# 更新後データを１項目１行に分解
	tmpfile7=/tmp/csvutil.${RND}.$$.7.tmp	# 更新されなかったデータを１項目１行に分解
	tmpfile8=/tmp/csvutil.${RND}.$$.8.tmp	# 新規追加項目を１項目１行に分解
	tmpfile9=/tmp/csvutil.${RND}.$$.9.tmp	# 更新されたレコード
	tmpfile10=/tmp/csvutil.${RND}.$$.10.tmp	# 項目の順序を保存するファイル
	tmpfile11=/tmp/csvutil.${RND}.$$.11.tmp	# ソートされたインプット
	sortSw=off
	updSw=off
	file=""
	cmd=""
	dat=""
	while [ "$#" != "0" ]
	do
		str="$1"
		if [ "$#" = "1" ]
		then
			if [ "X${str}" = "X-" ]
			then
				tmpfile1=/tmp/csvutil.${RND}.$$.1.tmp
				cat >${tmpfile1}
				file=${tmpfile1}
			else
				file=${str}
			fi
		else
			if [ "X${str}" = "X-s" ]
			then
				sortSw=on
			elif [ "X${str}" = "X-d" ]
			then
				updSw=on
			elif [ "X${updSw}" = "Xon" ]
			then
				str=`echo "$1" | sed -e 's/"/\\"/g'`
				if [ "X${dat}" = "X" ]
				then
					dat="${str}"
				else
					dat="${dat}${TAB}${str}"
				fi
			else
				str=`echo "$1" | sed -e 's/"/\\\\"/g'`
				if [ "X${cmd}" = "X" ]
				then
					cmd="egrep \"^${str}${TAB}|^${str}$|${TAB}${str}${TAB}|${TAB}${str}$\""
				else
					cmd="${cmd}|egrep \"^${str}${TAB}|^${str}$|${TAB}${str}${TAB}|${TAB}${str}$\""
				fi
			fi
		fi
		shift
	done

	if [ "X${sortSw}" = "Xon" ]
	then
		sort ${file} | tee ${tmpfile11} | eval "$cmd" >${tmpfile2}
		join -t "${LF}" -1 1 -2 1 -v 1 ${tmpfile11} ${tmpfile2} >${tmpfile3}
	else
		cat ${file} | eval "$cmd" >${tmpfile2}
		join -t "${LF}" -1 1 -2 1 -v 1 ${file} ${tmpfile2} >${tmpfile3}
	fi

	touch ${tmpfile9}
	IFSSAVE="${IFS}"
	IFS=$'\n'
	for i in `cat ${tmpfile2}`
	do
		echo "$i" | tr '\t' '\n' | tr '=' '\t' | cat -n | sed -e 's/^ *//' | sort -t "${TAB}" -k 2,2 >${tmpfile10}
		echo "$i" | tr '\t' '\n' | tr '=' '\t' | sort >${tmpfile4}
		echo "${dat}" | tr '\t' '\n' | tr '=' '\t' | sort >${tmpfile5}
		join -t "${TAB}" -1 1 -2 1 -o 1.1,2.2 ${tmpfile4} ${tmpfile5} >${tmpfile6}
		join -t "${TAB}" -1 1 -2 1 -v 1 ${tmpfile4} ${tmpfile5} >${tmpfile7}
		join -t "${TAB}" -1 1 -2 1 -v 2 ${tmpfile4} ${tmpfile5} >${tmpfile8}
		(
			cat ${tmpfile6} ${tmpfile7} ${tmpfile8} | 
				sort | 
				join -t "${TAB}" -1 2 -2 1 -a 2 -o 1.1,2.1,2.2 ${tmpfile10} - |
				sed -e "s/^${TAB}/65534${TAB}/" |
				sort -t "${TAB}" -k 1,1n -k 2,2 |
				cut -d "${TAB}" -f 2,3 |
				tr '\t' '=' | 
				tr '\n' '\t' | 
				sed -e "s/${TAB}$//"
			echo ""
		) >>${tmpfile9}
	done
	IFS="${IFSSAVE}"

	if [ "X${tmpfile1}" = "X" ]
	then
		sort ${tmpfile3} ${tmpfile9} >${file}
	else
		sort ${tmpfile3} ${tmpfile9}
	fi
	rm -f ${tmpfile1} ${tmpfile2} ${tmpfile3} ${tmpfile4} ${tmpfile5} ${tmpfile6} ${tmpfile7} ${tmpfile8} ${tmpfile9} ${tmpfile10} ${tmpfile11}
}

function csvGetValue(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvGetValue {record|-} item'
		echo 'Get value of item from record. If record is -, read stdin instead of record.'
		return 0
	fi

	record=`echo "$1" | sed -e 's/"/\\"/g'`
	item=`echo "$2" | sed -e 's/"/\\"/g'`

	TAB=`echo -n -e "\t"`
	IFSSAVE="${IFS}"
	IFS=$'\n'
	if [ "X${record}" = "X-" ]
	then
		for i in `tr '\t' '\n'`
		do
			echo "$i" | egrep "^${item}=" | cut -d "=" -f 2-
		done
	else
		for i in `echo "${record}"|tr '\t' '\n'`
		do
			echo "$i" | egrep "^${item}=" | cut -d "=" -f 2-
		done
	fi
	IFS="${IFSSAVE}"
}

