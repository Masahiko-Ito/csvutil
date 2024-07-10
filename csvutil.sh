#! /bin/sh

function csvSearch(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvSearch [-s] "item1=value1" "item2=value2" ... {filename|-}'
		echo 'Search records by condition of items from filename or stdin(-) and output to stdout.'
		echo '  -s    Output should be sorted.'
		return 0
	fi

	csvSearch_TAB=`echo -n -e "\t"`
	csvSearch_sortSw=off
	csvSearch_cmd=""
	while [ "$#" != "0" ]
	do
		csvSearch_str=`echo "$1" | sed -e 's/"/\\\\"/g'`
		if [ "$#" = "1" ]
		then
			if [ "X${csvSearch_str}" = "X-" ]
			then
				if [ "X${csvSearch_sortSw}" = "Xon" ]
				then
					csvSearch_cmd="sort|${csvSearch_cmd}"
				else
					csvSearch_cmd="cat|${csvSearch_cmd}"
				fi
			else
				if [ "X${csvSearch_sortSw}" = "Xon" ]
				then
					csvSearch_cmd="sort ${csvSearch_str}|${csvSearch_cmd}"
				else
					csvSearch_cmd="cat ${csvSearch_str}|${csvSearch_cmd}"
				fi
			fi
		else
			if [ "X${csvSearch_str}" = "X-s" ]
			then
				csvSearch_sortSw=on
			else
				if [ "X${csvSearch_cmd}" = "X" ]
				then
					csvSearch_cmd="egrep \"^${csvSearch_str}${csvSearch_TAB}|^${csvSearch_str}$|${csvSearch_TAB}${csvSearch_str}${csvSearch_TAB}|${csvSearch_TAB}${csvSearch_str}$\""
				else
					csvSearch_cmd="${csvSearch_cmd}|egrep \"^${csvSearch_str}${csvSearch_TAB}|^${csvSearch_str}$|${csvSearch_TAB}${csvSearch_str}${csvSearch_TAB}|${csvSearch_TAB}${csvSearch_str}$\""
				fi
			fi
		fi
		shift
	done

	eval "${csvSearch_cmd}"
}

function csvAppend(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvAppend [-s] "item1=value1" "item2=value2" ... {filename|-}'
		echo 'Append a record into filename. If filename is -, append a record into stdin and output to stdout.'
		echo '  -s    Output should be sorted.'
		return 0
	fi

	csvAppend_TAB=`echo -n -e "\t"`; export csvAppend_TAB
	csvAppend_tmpfile1=/tmp/csvutil.${RND}.$$.1.tmp
	csvAppend_sortSw=off
	csvAppend_rec=""
	csvAppend_outf=""
	while [ "$#" != "0" ]
	do
		csvAppend_str=`echo "$1" | sed -e 's/"/\\"/g'`
		if [ "$#" = "1" ]
		then
			csvAppend_outf="${csvAppend_str}"
		else
			if [ "X${csvAppend_str}" = "X-s" ]
			then
				csvAppend_sortSw=on
			else
				if [ "X${csvAppend_rec}" = "X" ]
				then
					csvAppend_rec="${csvAppend_str}"
				else
					csvAppend_rec="${csvAppend_rec}${csvAppend_TAB}${csvAppend_str}"
				fi
			fi
		fi
		shift
	done

	if [ "X${csvAppend_outf}" = "X-"  ]
	then
		if [ "X${csvAppend_sortSw}" = "Xon" ]
		then
			(
				cat
				echo "${csvAppend_rec}"
			) | sort
		else
			cat
			echo "${csvAppend_rec}"
		fi
	else
		if [ "X${csvAppend_sortSw}" = "Xon" ]
		then
			(
				cat ${csvAppend_outf}
				echo "${csvAppend_rec}"
			) | sort >${csvAppend_tmpfile1}
			mv -f ${csvAppend_tmpfile1} ${csvAppend_outf}
		else
			echo "${csvAppend_rec}" >>${csvAppend_outf}
		fi
	fi
}

function csvDelete(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvDelete [-s] "item1=value1" "item2=value2" ... {filename|-}'
		echo 'Delete records by condition of items from filename. If filename is -, delete records from stdin and output to stdout.'
		echo '  -s                    force to sort input before delete.'
		echo 'Caution: Input records must be sorted and output is always sorted.'
		return 0
	fi

	csvDelete_TAB=`echo -n -e "\t"`
	csvDelete_LF=`echo -n -e "\n"`
	RND=${RANDOM}
	csvDelete_tmpfile1=""
	csvDelete_tmpfile2=/tmp/csvutil.${RND}.$$.2.tmp
	csvDelete_tmpfile3=/tmp/csvutil.${RND}.$$.3.tmp
	csvDelete_file=""
	csvDelete_sortSw=off
	csvDelete_cmd=""
	while [ "$#" != "0" ]
	do
		csvDelete_str=`echo "$1" | sed -e 's/"/\\\\"/g'`
		if [ "$#" = "1" ]
		then
			if [ "X${csvDelete_str}" = "X-" ]
			then
				csvDelete_tmpfile1=/tmp/csvutil.${RND}.$$.1.tmp
				if [ "X${csvDelete_sortSw}" = "Xon" ]
				then
					sort >${csvDelete_tmpfile1}
				else
					cat >${csvDelete_tmpfile1}
				fi
				csvDelete_cmd="cat ${csvDelete_tmpfile1}|${csvDelete_cmd}"
			else
				csvDelete_file=${csvDelete_str}
				if [ "X${csvDelete_sortSw}" = "Xon" ]
				then
					sort "${csvDelete_str}" >"${csvDelete_tmpfile3}"
					mv -f "${csvDelete_tmpfile3}" "${csvDelete_str}"
				fi
				csvDelete_cmd="cat ${csvDelete_str}|${csvDelete_cmd}"
			fi
		else
			if [ "X${csvDelete_str}" = "X-s" ]
			then
				csvDelete_sortSw=on
			else
				if [ "X${csvDelete_cmd}" = "X" ]
				then
					csvDelete_cmd="egrep \"^${csvDelete_str}${csvDelete_TAB}|^${csvDelete_str}$|${csvDelete_TAB}${csvDelete_str}${csvDelete_TAB}|${csvDelete_TAB}${csvDelete_str}$\""
				else
					csvDelete_cmd="${csvDelete_cmd}|egrep \"^${csvDelete_str}${csvDelete_TAB}|^${csvDelete_str}$|${csvDelete_TAB}${csvDelete_str}${csvDelete_TAB}|${csvDelete_TAB}${csvDelete_str}$\""
				fi
			fi
		fi
		shift
	done

	if [ "X${csvDelete_tmpfile1}" = "X" ]
	then
		eval "${csvDelete_cmd}" | join -t "${csvDelete_LF}"  -1 1 -2 1 -v 1 ${csvDelete_file} - >${csvDelete_tmpfile2} && mv -f ${csvDelete_tmpfile2} ${csvDelete_file}
	else
		eval "${csvDelete_cmd}" | join -t "${csvDelete_LF}"  -1 1 -2 1 -v 1 ${csvDelete_tmpfile1} -
	fi
	rm -f ${csvDelete_tmpfile1} ${csvDelete_tmpfile2} ${csvDelete_tmpfile3}
}

function csvUpdate(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvUpdate [-s] "item1=value1" "item2=value2" ... -d "item3=value3" "item4=value4" ... {filename|-}'
		echo 'Update records by condition of items in filename. If filename is -, update records in stdin and output to stdout.'
		echo '  -s                    force to sort input before update.'
		echo '  -d "item=value"       "item=value" before -d are keys point records to update.'
		echo '                        "item=value" after -d are new values.'
		echo 'Caution: Input records must be sorted and output is always sorted.'
		return 0
	fi

	csvUpdate_TAB=`echo -n -e "\t"`
	csvUpdate_LF=`echo -n -e "\n"`
	csvUpdate_RND=${RANDOM}
	csvUpdate_tmpfile1=""
	csvUpdate_tmpfile2=/tmp/csvutil.${csvUpdate_RND}.$$.2.tmp	# 更新対象データ
	csvUpdate_tmpfile3=/tmp/csvutil.${csvUpdate_RND}.$$.3.tmp	# 更新対象外データ	
	csvUpdate_tmpfile4=/tmp/csvutil.${csvUpdate_RND}.$$.4.tmp	# 更新対象データを１項目１行に分解
	csvUpdate_tmpfile5=/tmp/csvutil.${csvUpdate_RND}.$$.5.tmp	# 更新トランザクションを１項目１行に分解
	csvUpdate_tmpfile6=/tmp/csvutil.${csvUpdate_RND}.$$.6.tmp	# 更新後データを１項目１行に分解
	csvUpdate_tmpfile7=/tmp/csvutil.${csvUpdate_RND}.$$.7.tmp	# 更新されなかったデータを１項目１行に分解
	csvUpdate_tmpfile8=/tmp/csvutil.${csvUpdate_RND}.$$.8.tmp	# 新規追加項目を１項目１行に分解
	csvUpdate_tmpfile9=/tmp/csvutil.${csvUpdate_RND}.$$.9.tmp	# 更新されたレコード
	csvUpdate_tmpfile10=/tmp/csvutil.${csvUpdate_RND}.$$.10.tmp	# 項目の順序を保存するファイル
	csvUpdate_tmpfile11=/tmp/csvutil.${csvUpdate_RND}.$$.11.tmp	# ソートされたインプット
	csvUpdate_sortSw=off
	csvUpdate_updSw=off
	csvUpdate_file=""
	csvUpdate_cmd=""
	csvUpdate_dat=""
	while [ "$#" != "0" ]
	do
		csvUpdate_str="$1"
		if [ "$#" = "1" ]
		then
			if [ "X${csvUpdate_str}" = "X-" ]
			then
				csvUpdate_tmpfile1=/tmp/csvutil.${csvUpdate_RND}.$$.1.tmp
				cat >${csvUpdate_tmpfile1}
				csvUpdate_file=${csvUpdate_tmpfile1}
			else
				csvUpdate_file=${csvUpdate_str}
			fi
		else
			if [ "X${csvUpdate_str}" = "X-s" ]
			then
				csvUpdate_sortSw=on
			elif [ "X${csvUpdate_str}" = "X-d" ]
			then
				csvUpdate_updSw=on
			elif [ "X${csvUpdate_updSw}" = "Xon" ]
			then
				csvUpdate_str=`echo "$1" | sed -e 's/"/\\"/g'`
				if [ "X${csvUpdate_dat}" = "X" ]
				then
					csvUpdate_dat="${csvUpdate_str}"
				else
					csvUpdate_dat="${csvUpdate_dat}${csvUpdate_TAB}${csvUpdate_str}"
				fi
			else
				csvUpdate_str=`echo "$1" | sed -e 's/"/\\\\"/g'`
				if [ "X${csvUpdate_cmd}" = "X" ]
				then
					csvUpdate_cmd="egrep \"^${csvUpdate_str}${csvUpdate_TAB}|^${csvUpdate_str}$|${csvUpdate_TAB}${csvUpdate_str}${csvUpdate_TAB}|${csvUpdate_TAB}${csvUpdate_str}$\""
				else
					csvUpdate_cmd="${csvUpdate_cmd}|egrep \"^${csvUpdate_str}${csvUpdate_TAB}|^${csvUpdate_str}$|${csvUpdate_TAB}${csvUpdate_str}${csvUpdate_TAB}|${csvUpdate_TAB}${csvUpdate_str}$\""
				fi
			fi
		fi
		shift
	done

	if [ "X${csvUpdate_sortSw}" = "Xon" ]
	then
		sort ${csvUpdate_file} | tee ${csvUpdate_tmpfile11} | eval "$csvUpdate_cmd" >${csvUpdate_tmpfile2}
		join -t "${csvUpdate_LF}" -1 1 -2 1 -v 1 ${csvUpdate_tmpfile11} ${csvUpdate_tmpfile2} >${csvUpdate_tmpfile3}
	else
		cat ${csvUpdate_file} | eval "$csvUpdate_cmd" >${csvUpdate_tmpfile2}
		join -t "${csvUpdate_LF}" -1 1 -2 1 -v 1 ${csvUpdate_file} ${csvUpdate_tmpfile2} >${csvUpdate_tmpfile3}
	fi

	touch ${csvUpdate_tmpfile9}
	csvUpdate_IFSSAVE="${IFS}"
	IFS=$'\n'
	for i in `cat ${csvUpdate_tmpfile2}`
	do
		echo "$i" | tr '\t' '\n' | tr '=' '\t' | cat -n | sed -e 's/^ *//' | sort -t "${csvUpdate_TAB}" -k 2,2 >${csvUpdate_tmpfile10}
		echo "$i" | tr '\t' '\n' | tr '=' '\t' | sort >${csvUpdate_tmpfile4}
		echo "${csvUpdate_dat}" | tr '\t' '\n' | tr '=' '\t' | sort >${csvUpdate_tmpfile5}
		join -t "${csvUpdate_TAB}" -1 1 -2 1 -o 1.1,2.2 ${csvUpdate_tmpfile4} ${csvUpdate_tmpfile5} >${csvUpdate_tmpfile6}
		join -t "${csvUpdate_TAB}" -1 1 -2 1 -v 1 ${csvUpdate_tmpfile4} ${csvUpdate_tmpfile5} >${csvUpdate_tmpfile7}
		join -t "${csvUpdate_TAB}" -1 1 -2 1 -v 2 ${csvUpdate_tmpfile4} ${csvUpdate_tmpfile5} >${csvUpdate_tmpfile8}
		(
#				join -t "${csvUpdate_TAB}" -1 2 -2 1 -a 2 -e 65534 -o 1.1,2.1,2.2 ${csvUpdate_tmpfile10} - |
			cat ${csvUpdate_tmpfile6} ${csvUpdate_tmpfile7} ${csvUpdate_tmpfile8} | 
				sort | 
				join -t "${csvUpdate_TAB}" -1 2 -2 1 -a 2 -o 1.1,2.1,2.2 ${csvUpdate_tmpfile10} - |
				sed -e "s/^${csvUpdate_TAB}/65534${csvUpdate_TAB}/" |
				sort -t "${csvUpdate_TAB}" -k 1,1n -k 2,2 |
				cut -d "${csvUpdate_TAB}" -f 2,3 |
				tr '\t' '=' | 
				tr '\n' '\t' | 
				sed -e "s/${csvUpdate_TAB}$//"
			echo ""
		) >>${csvUpdate_tmpfile9}
	done
	IFS="${csvUpdate_IFSSAVE}"

	if [ "X${csvUpdate_tmpfile1}" = "X" ]
	then
		sort ${csvUpdate_tmpfile3} ${csvUpdate_tmpfile9} >${csvUpdate_file}
	else
		sort ${csvUpdate_tmpfile3} ${csvUpdate_tmpfile9}
	fi
	rm -f ${csvUpdate_tmpfile1} ${csvUpdate_tmpfile2} ${csvUpdate_tmpfile3} ${csvUpdate_tmpfile4} ${csvUpdate_tmpfile5} ${csvUpdate_tmpfile6} ${csvUpdate_tmpfile7} ${csvUpdate_tmpfile8} ${csvUpdate_tmpfile9} ${csvUpdate_tmpfile10} ${csvUpdate_tmpfile11}
}

function csvGetValue(){
	if [ "X$1" = "X-h" -o "X$1" = "X--help" ]
	then
		echo 'Usage : csvGetValue {record|-} item'
		echo 'Get value of item from record. If record is -, read stdin instead of record.'
		return 0
	fi

	csvGetValue_record=`echo "$1" | sed -e 's/"/\\"/g'`
	csvGetValue_item=`echo "$2" | sed -e 's/"/\\"/g'`

	csvGetValue_TAB=`echo -n -e "\t"`
	csvGetValue_IFSSAVE="${IFS}"
	IFS=$'\n'
	if [ "X${csvGetValue_record}" = "X-" ]
	then
		for i in `tr '\t' '\n'`
		do
			echo "$i" | egrep "^${csvGetValue_item}=" | cut -d "=" -f 2-
		done
	else
		for i in `echo "${csvGetValue_record}"|tr '\t' '\n'`
		do
			echo "$i" | egrep "^${csvGetValue_item}=" | cut -d "=" -f 2-
		done
	fi
	IFS="${csvGetValue_IFSSAVE}"
}

