#!/bin/bash

################ VARIABLES GLOBALES ################

test_number=1
display_error_msg=1
GREEN="\033[38;5;113m"
RED="\033[38;5;160m"
GREY="\033[38;5;109m"
ORANGE="\033[38;5;208m"
WHITE="\033[38;5;15m"
CYAN="\033[38;5;51m"
PURPLE="\033[38;5;135m"
RESET="\033[0m"


################ FONCTIONS ################

add_newline()
{
    echo >> diff_minishell.txt
    echo >> diff_bash.txt
}

delete_file()
{
    for file in $@
    do
        if [ -f $file ]
        then
            rm $file
        fi
    done
}

run_shell()
{
    param_number=0

    echo $2 | "$1" > buffer 2>&1
    for opt in "$@"
    do
        if [ $param_number \> 1 ]
        then
            cat < buffer | $opt > buffer2 2>&1
            cat < buffer2 > buffer
            rm buffer2
        fi
        let "param_number+=1"
    done
    if [ $display_error_msg == 0 ]
    then
        cat < buffer | grep -v Minishell: > buffer2
        cat < buffer2 > buffer
        cat < buffer | grep -v bash: > buffer2
        cat < buffer2 > buffer
    fi
    cat < buffer
}

run_return()
{
    echo $1 | ../minishell > /dev/random 2>&1 ; echo $? > diff_minishell.txt
    echo $1 | bash > /dev/random 2>&1 ; echo $? > diff_bash.txt
    diff --text diff_minishell.txt diff_bash.txt > /dev/random 2>&1
    result=$?
    if [ $result = 0 ]
    then
        echo -e "$GREEN TEST $test_number ✓$RESET "
    elif [ $result = 1 ]
    then
        echo -e "$RED\n======================== TEST $test_number ✗ ========================$RESET"
        echo -ne "\033[38;5;90mCommand :$RESET"
        echo $1

        echo -e "$GREY\nMinishell exit status\n--------------------------------------------------------$RESET"
        diff --text diff_minishell.txt diff_bash.txt | grep '<' | cut -c 2-
        echo -e "$GREY-------------------------------------------------------------$RESET"

        echo -e "$ORANGE\nBash exit status\n--------------------------------------------------------$RESET"
        diff --text diff_minishell.txt diff_bash.txt | grep '>' | cut -c 2-
        echo -e "$ORANGE-------------------------------------------------------------\n$RESET"
    fi
    let "test_number+=1"
}

run_test()
{
    run_shell '../minishell' "$@" > diff_minishell.txt
    run_shell 'bash' "$@"  > diff_bash.txt
    diff --text diff_minishell.txt diff_bash.txt > /dev/random 2>&1
    result=$?
    if [ $result = 0 ]
    then
        echo -e "$GREEN TEST $test_number ✓$RESET"
    elif [ $result = 1 ]
    then
        echo -e "$RED\n======================== TEST $test_number ✗ ========================$RESET"
        echo -ne "\033[38;5;90mCommand :$RESET "
        echo $1

        echo -e "$GREY\nMinishell output\n-------------------------------------------------------------$RESET"
        diff --text diff_minishell.txt diff_bash.txt | grep '<' | cut -c 2-
        echo -e "$GREY-------------------------------------------------------------$RESET"

        echo -e "$ORANGE\nBash output\n-------------------------------------------------------------$RESET"
        diff --text diff_minishell.txt diff_bash.txt | grep '>' | cut -c 2-
        echo -e "$ORANGE-------------------------------------------------------------\n$RESET"
    fi
    let "test_number+=1"
}

run_leaks()
{
    check=0
    echo $1 | valgrind --leak-check=full ../minishell > leaks_minishell.txt 2>&1
    cat < leaks_minishell.txt | grep "definitely lost:" | cut -c 30- > buffer
    cat < buffer > boucle
    while read -r line
    do
        if [ $(echo $line | head -c 1) != '0' ]
        then
            check=1
        fi
    done < boucle
    if [ $check = 1 ]
    then
        echo -e "$RED\n======================== TEST $test_number LEAKED ========================$RESET"
        echo -ne "\033[38;5;90mCommand :$RESET "
        echo $1

        echo -e "$GREY\nLeak amount\n-------------------------------------------------------------$RESET"
        cat < buffer
        echo -e "$GREY-------------------------------------------------------------\n$RESET"
    else
        echo -e "$GREEN TEST $test_number ✓$RESET"
    fi
    let "test_number+=1"
}


################ CLEAN SHELL ################

rm -rf add_path test_cd ~/test_cd test_files ../minishell.dSYM ...
delete_file "a b ../a ../b buffer ../buffer buffer2 prog diff_minishell.txt diff_bash.txt ../diff_minishell.txt ../diff_bash.txt leaks_minishell.txt boucle"
if [ "$1" = "clean" ]
then
    exit
fi


################ SETUP SHELL ################

LC_ALL=C
gcc test.c -o prog
mkdir add_path && cd add_path && gcc ../ls.c -o ls && cd ..
cd .. && make && cd minishell_tester

echo -e "$WHITE\n\nDisplay error messages ? [$GREEN Y$WHITE /$RED N $WHITE]$RESET"
echo -ne "$CYAN>> $RESET"
read user_input
if [ $user_input = 'N' ]
then
    display_error_msg=0
fi


################ SCRIPT ################

echo -e "\n\n$CYAN#############################################################################"
echo -e "#                             EXECUTION TESTS                               #"
echo -e "#############################################################################$RESET\n"


#ECHO
run_test 'echo test'
run_test 'echo echo'
run_test 'echo'
run_test 'echo -n -n lala'
add_newline
run_test 'echo \n'
run_test 'echo lala\nlala'
run_test 'echo "lala\nlala"'
run_test "echo 'lala\nlala'"
run_test 'echo "test""test" "lala"'
run_test 'echo "test"test"" "lala"'
run_test 'echo "test"\""test" "lala"'
run_test 'echo "test"\"\""\"test" "lala"'
run_test "echo 'test''test''lala'"
run_test "echo 'test'\\'test'\''lala'"
run_test "echo 'test''test''lala'"
run_test 'echo test "" test "" test'
run_test 'echo test """" test """" test'
run_test 'echo test "" "" "" test'
run_test 'echo "" test "" test "" test ""'
run_test 'echo -n oui'
add_newline
run_test 'echo $PWD'
run_test 'echo $OLDPWD'
run_test 'echo \$PWD'
run_test 'echo \\$PWD'
run_test 'echo $NOVAR'
run_test 'pwd ; echo $PWD ; echo OLDPWD ; unset PWD ; echo $PWD ; echo $OLDPWD ; cd .. ; echo $OLDPWD ; pwd ; echo $OLDPWD ; cd .. ; pwd ; echo $OLDPWD'
run_test 'echo ${PWD}'
run_test 'echo ${PATH'
run_test 'echo $PWD}'

#ENV
run_test 'env' 'grep -v _=' 'sort'
run_test 'env lala' 'grep -v env:'
export SHLVL=8 && run_test 'env' 'grep -a SHLVL'
export SHLVL=test && run_test 'env' 'grep -a SHLVL'
export SHLVL=0 && run_test 'env' 'grep -a SHLVL'
export SHLVL=+23 && run_test 'env' 'grep -a SHLVL'
export SHLVL=-10 && run_test 'env' 'grep -a SHLVL'
export SHLVL=8+8 && run_test 'env' 'grep -a SHLVL'
export SHLVL=++9 && run_test 'env' 'grep -a SHLVL'
export SHLVL=-8+8 && run_test 'env' 'grep -a SHLVL'
export SHLVL=9-8 && run_test 'env' 'grep -a SHLVL'
run_test 'export testvar ; env | grep -a testvar'
run_test 'export testvar= ; env | grep -a testvar'
run_test 'export testvar=0 ; env | grep -a testvar'
run_test 'export testvar=1234567 ; env | grep -a testvar'
run_test 'export testvar=lala ; env | grep -a testvar'
run_test 'export testvar=lala%lala ; env | grep -a testvar'
run_test 'export testvar=@lala ; env | grep -a testvar'
run_test 'export testvar10 ; env | grep -a testvar10'
run_test 'export testvar10= ; env | grep -a testvar10'
run_test 'export testvar10=10 ; env | grep -a testvar10'
run_test 'export _testvar ; env | grep -a _testvar'
run_test 'export _testvar= ; env | grep -a _testvar'
run_test 'export _testvar=10 ; env | grep -a _testvar'
run_test 'export _testvar=lala ; env | grep -a _testvar'
run_test 'export _testvar=lala10 ; env | grep -a _testvar'
run_test 'export _testvar10 ; env | grep -a _testvar10'
run_test 'export _testvar10= ; env | grep -a _testvar10'
run_test 'export _testvar10=lala ; env | grep -a _testvar10'
run_test 'export _testvar10=10; env | grep -a _testvar10'
run_test 'export _testvar10=lala10 ; env | grep -a _testvar10'
run_test 'export testvar=10 ; export testvar=20 ; env | grep -a testvar'


#EXPORT
run_test 'export' 'grep -v _=' 'sort'
export SHLVL=8 && run_test 'export' 'grep -a SHLVL'
export SHLVL=test && run_test 'export' 'grep -a SHLVL'
export SHLVL=0 && run_test 'export' 'grep -a SHLVL'
export SHLVL=+23 && run_test 'export' 'grep -a SHLVL'
export SHLVL=-10 && run_test 'export' 'grep -a SHLVL'
export SHLVL=8+8 && run_test 'export' 'grep -a SHLVL'
export SHLVL=++9 && run_test 'export' 'grep -a SHLVL'
export SHLVL=-8+8 && run_test 'export' 'grep -a SHLVL'
export SHLVL=9-8 && run_test 'export' 'grep -a SHLVL'
run_test 'export %' 
run_test 'export !' 
run_test 'export +' 
run_test 'export testvar ; export | grep -a testvar'
run_test 'export testvar= ; export | grep -a testvar'
run_test 'export testvar=0 ; export | grep -a testvar'
run_test 'export testvar=1234567 ; export | grep -a testvar'
run_test 'export testvar=lala ; export | grep -a testvar'
run_test 'export testvar=lala%lala ; export | grep -a testvar'
run_test 'export testvar=@lala ; export | grep -a testvar'
run_test 'export testvar10 ; export | grep -a testvar10'
run_test 'export testvar10= ; export | grep -a testvar10'
run_test 'export testvar10=10 ; export | grep -a testvar10'
run_test 'export _testvar ; export | grep -a _testvar'
run_test 'export _testvar= ; export | grep -a _testvar'
run_test 'export _testvar=10 ; export | grep -a _testvar'
run_test 'export _testvar=lala ; export | grep -a _testvar'
run_test 'export _testvar=lala10 ; export | grep -a _testvar'
run_test 'export _testvar10 ; export | grep -a _testvar10'
run_test 'export _testvar10= ; export | grep -a _testvar10'
run_test 'export _testvar10=lala ; export | grep -a _testvar10'
run_test 'export _testvar10=10; export | grep -a _testvar10'
run_test 'export _testvar10=lala10 ; export | grep -a _testvar10'
run_test 'export testvar=10 ; export testvar=20 ; export | grep -a testvar'
run_test 'export testvar=lala ; export ; export testvar=10 ; export' 'grep -v _=' 'sort'

#UNSET
run_test 'unset'
run_test 'unset novar'
run_test 'unset %' 
run_test 'export a ; export ; unset a ; export' 'grep -v _='
run_test 'export a= ; export ; unset a ; export' 'grep -v _='
run_test 'export a=10 ; export ; unset a ; export' 'grep -v _='
run_test 'export a=lala ; export ; unset a ; export' 'grep -v _='
run_test 'export a=?lala%lala; export ; unset a ; export' 'grep -v _='
run_test 'export a=a10a10 ; export ; unset a ; export' 'grep -v _='
run_test 'export a10 ; export ; unset a10 ; export' 'grep -v _='
run_test 'export a10= ; export ; unset a10 ; export' 'grep -v _='
run_test 'export a10=10 ; export ; unset a10 ; export' 'grep -v _='
run_test 'export a10=lala ; export ; unset a10 ; export' 'grep -v _='
run_test 'export a10=?lala%lala; export ; unset a10 ; export' 'grep -v _='
run_test 'export a10=a10a10 ; export ; unset a10 ; export' 'grep -v _='
run_test 'export _a10 ; export ; unset _a10 ; export' 'grep -v _='
run_test 'export _a10= ; export ; unset _a10 ; export' 'grep -v _='
run_test 'export _a10=10 ; export ; unset _a10 ; export' 'grep -v _='
run_test 'export _a10=lala ; export ; unset _a10 ; export' 'grep -v _='
run_test 'export _a10=?lala%lala; export ; unset _a10 ; export' 'grep -v _='
run_test 'export _a10=a10a10 ; export ; unset _a10 ; export' 'grep -v _='


#PWD
run_test 'pwd'
run_test 'pwd test'
run_test 'pwd test lala'
run_test 'pwd "test"'
run_test 'pwd ; cd .. ; pwd ; cd / ; pwd ; cd . ; pwd ; cd ~/ ; pwd'
run_test 'pwd .'
run_test 'pwd ..'

#CD
mkdir test_cd
mkdir ~/test_cd
run_test 'pwd ; cd ; pwd'
run_test 'pwd ; cd .. ; pwd'
export dir=${PWD%/*} && run_test 'pwd ; cd $dir ; pwd' && unset dir
run_test 'pwd ; cd test_cd ; pwd'
run_test 'pwd ; cd ~/ ; pwd'
run_test 'pwd ; cd ~/test_cd ; pwd'
run_test 'pwd ; cd .. ; pwd ; cd .. ; pwd ; cd ~/ ; pwd'
run_test 'pwd ; cd /'
run_test 'pwd ; cd error ; pwd'
run_test 'pwd ; cd error error ; pwd'
run_test 'pwd ; cd test_cd error ; pwd'
run_test 'pwd ; cd error test_cd error ; pwd'
run_test 'pwd ; cd ~/test_cd error ; pwd'
run_test 'pwd ; cd error ~/test_cd error ; pwd'
run_test 'pwd ; cd .. ; pwd ; cd .. ; pwd ; cd .. ; pwd ; cd .. ; pwd ; cd .. ; pwd ; cd .. ; pwd '
run_test 'pwd ; cd .. | pwd'
run_test 'pwd | cd | pwd ; cd | pwd'
run_test 'pwd ; cd ../minishell_tester ; pwd'
run_test 'pwd ; cd ../error ; pwd'
run_test 'pwd ; cd . ; pwd'
run_test 'pwd ; cd ./ ; pwd'
run_test 'pwd ; cd ../ ; pwd'
run_test 'pwd ; cd ... ; pwd'
run_test 'pwd ; cd .error ; pwd'
run_test 'pwd ; cd ..error ; pwd'
echo -e "\n$ORANGE >> THOSE TESTS MAY HAVE TO BE CHANGED BY A DIFFERENT PATH $RESET"
run_test 'pwd ; cd ../../../Bureau/../Bureau/../Bureau ; pwd'
run_test 'pwd ; cd ./../../../Bureau/../Bureau/../Bureau ; pwd'
run_test 'pwd ; cd ./../../../Bureau/././././../Bureau/././././../Bureau ; pwd'
run_test 'pwd ; cd ~/../../home/../home/user42/Bureau/../Bureau/../Bureau ; pwd'
run_test 'pwd ; cd ~/.. ; pwd'
run_test 'pwd ; cd ../.. ; cd minishell/../minishell/.. ; pwd'
run_test 'pwd ; cd ../../ ; cd ./minishell/.././minishell/../. ; pwd'
run_test 'pwd ; cd ~ ; cd ../../../../../ ; pwd'
run_test 'pwd ; cd ../.../ ; pwd'
run_test 'pwd ; cd ../... ; pwd'
mkdir ...
run_test 'pwd ; cd ... ; pwd'
run_test 'pwd ; cd ../minishell_tester/... ; pwd'
run_test 'pwd ; cd .../../..././././../... ; pwd'
rm -rf test_cd ~/test_cd ...


#EXIT
run_test 'exit'
run_test 'exit | echo lala'
run_test 'exit ; echo lala'
run_test 'exit 0'
run_test 'exit 1'
run_test 'exit 255'
run_test 'exit 256'
run_test 'exit 1000'
run_test 'exit 9223372036854775807'
run_test 'exit +0'
run_test 'exit +1'
run_test 'exit +255'
run_test 'exit +256'
run_test 'exit +1000'
run_test 'exit +9223372036854775807'
run_test 'exit -0'
run_test 'exit -1'
run_test 'exit -255'
run_test 'exit -256'
run_test 'exit -1000'
run_test 'exit -9223372036854775808'
run_test 'exit --1'
run_test 'exit ++1'
run_test 'exit ++1'
run_test 'exit lala'
run_test 'exit ?'
run_test 'exit @@'
run_test 'exit 9223372036854775810'
run_test 'exit -9223372036854775810'
run_test 'export a ; exit $a'
run_test 'export a= ; exit $a'
run_test 'export a=77 ; exit $a'
run_test 'export % ; exit $?'
run_test 'exit $a'
run_test 'exit 55 55'
run_test 'exit +55 55'
run_test 'exit -55 55'
run_test 'exit lala lala'
run_test 'exit 55 lala'
run_test 'exit lala 55'




#VARIABLES D'ENVIRONNEMENTS
run_test 'export test=lala ; echo $test ; export $test=10 ; echo $lala'
run_test 'export test=lala ; export $test=a10 ; export $lala=test ; unset $lala ; export' 'grep -v _='
run_test 'export a b c ; unset a c ; export' 'grep -v _='
run_test 'export test=echo val=lala ; $test $lala ; export' 'grep -v _='
run_test 'echo $TEST$TEST=lala'
run_test 'echo $TEST=lala$TEST'
run_test 'echo $TEST$TEST=lala$TEST'
run_test 'echo $TEST$TEST=$TEST=$TEST=$TEST=$TEST=$TEST'
run_test 'echo $1TEST'
run_test 'echo $10000TEST'
run_test 'echo $99TEST'
run_test 'echo $=TEST'
run_test 'echo $1 "" $9 "" $4 "" $7'
run_test 'echo $?TEST$?'
run_test 'echo "$PWD"'
run_test 'echo "$LALA"'
run_test "echo \'$PWD\'"
run_test "echo \'$LALA\'"


#PIPE
run_test 'export a | echo lala ; export' 'grep -v _='
run_test 'export | echo lala'
run_test 'unset PWD | echo lala ; export' 'grep -v _='
run_test 'cd .. | echo lala ; export' 'grep -v _='
run_test 'echo test | echo lala'
run_test 'pwd | echo lala'
run_test 'env | echo lala'
run_test 'cat bible.txt | grep testifieth'
echo -e "\n$ORANGE >> THIS TEST MAY TAKE A WHILE TO ACHIEVE $RESET"
run_test 'find / | grep cores'
run_test 'echo test | cat | cat | cat | cat | cat | grep test'


#PARSING
run_test 'echo \n\n'
run_test 'echo ""' 
run_test 'echo \|' 
run_test 'echo \"\"' 
run_test 'echo \\'
run_test 'echo \\\\' 
run_test 'echo \|\|' 
run_test 'echo \\\|\\\|' 
run_test 'echo \\"\\"' 
run_test 'echo \$ \"' 
run_test 'echo \[ \] \\ \`' 
run_test 'echo \: \@ \< \> \= \?' 
run_test 'echo \"a\"' 
run_test 'echo \\"a\\"' 
run_test 'echo "\\a\\"' 
run_test 'echo \\\"a\"\\' 
run_test 'echo a\\a' 
run_test 'echo a\"\a' 
run_test 'echo $' 
run_test 'echo \$'
run_test 'echo \\$' 
run_test 'echo $USER' 
run_test 'echo \$USER' 
run_test 'echo \\$USER' 
run_test 'echo \\\$USER' 
run_test 'echo $war' 
run_test 'echo \$war' 
run_test 'echo \\$war' 
run_test 'echo \\\$war' 
run_test 'echo \|\\$USER' 
run_test 'echo \|\\\$USER' 
run_test 'echo \\\"$USER' 
run_test 'echo \|\\$USER' 
run_test 'echo \|\\\$USER' 
run_test 'echo \\\"$USER' 
run_test 'echo \$ \! \@ \# \% \^ \& \* \( \) \_ \+ \|' 
run_test 'echo \$ \! \@ \# \% \^ \& \* \( \) \_ \+ \|' 
run_test 'echo \"\$ \! \@ \# \% \^ \& \* \( \) \_ \+ \|\"' 
run_test 'echo \$ \! \@ \# \% \^ \& \* \( \) \_ \+ \|' 
run_test 'echo \$ \! \@ \# \% \^ \& \* \( \) \_ \+ \|' 
run_test 'echo \\\$ \\\! \\\@ \\\# \\\% \\\^ \\\& \\\* \\\( \\\) \\\_ \\\+ \\\|' 
run_test 'echo \: \! \< \> \= \?' 
run_test 'echo "\: \! \< \> \= \?"' 
run_test 'echo \[ \] \\ \`' 
run_test 'echo \\ \\ \\'
run_test 'echo \\ \\\ \\'
run_test 'echo \\ \ \\'
run_test 'echo \\ \ \\'
run_test 'echo \\ $ \\'
run_test 'echo \\ \$ \\'
run_test 'echo \\ \\$ \\'
run_test 'echo \\ | \\'
run_test 'echo \\ \| \\'
run_test 'echo \\ \\| \\'
run_test 'echo \\ ; \\'
run_test 'echo \\ \; \\'
run_test 'echo \\ \\; \\'
run_test 'echo \ \\ \\'
run_test 'echo \ \\\ \\'
run_test 'echo \ \ \\'
run_test 'echo \ \ \\'
run_test 'echo \ \$ \\'
run_test 'echo \ \\$ \\'
run_test 'echo \ \| \\'
run_test 'echo \ \\| \\'
run_test 'echo \ \; \\'
run_test 'echo \ \\; \\'
run_test 'echo "\\"\\'
run_test 'echo \"\\\"\\'
run_test 'echo "\\\|"\\'
run_test 'echo \"\\\|\"\\'
run_test 'echo \"\\$TEST\|\"$1\\$444'
run_test 'echo \"\\\$TEST\|\"\$1\\\$444'
run_test 'echo "*"\\-\% \\ \$'
run_test 'echo \"*"\\-\% \\ \$"'
run_test "echo \'"
run_test "echo \\'\"\'\""
run_test "echo \\'\"\'\""
run_test "echo \'\"\'\""
run_test "echo \'\"\'\""
run_test "echo \\'\"\\'\""
run_test "echo \\'\"\\\\'\""
run_test "echo \\'\"\\'\""
run_test "echo lala;echo test;echo lala"
run_test "echo lala|echo test|echo lala"
run_test "echo lala;echo test|echo lala"
run_test "echo lala|echo test;echo lala"
run_test "echo lala ;   echo   test     ;echo      lala"
run_test "echo lala             |echo       test |                            echo  lala"
run_test "echo lala ;   echo test| echo        lala"
run_test "echo        lala|echo test ;echo                                   lala"


#REDIRECTIONS
mkdir test_files
run_test 'echo test > a ; cat < a'
run_test 'echo lala >a ; cat <a'
run_test 'echo test>a ; cat<a'
run_test 'echo lala> a ; cat< a'
run_test 'echo test >a ; cat <a'
run_test 'echo lala> a ; cat< a'
run_test 'echo test        >a ; cat<        a'
run_test 'echo lala            >     a ; cat        <       a'
run_test 'echo test > test_files/a ; cat < test_files/a'
run_test 'echo lala >test_files/a ; cat <test_files/a'
run_test 'echo test > b ; echo test add >> b ; cat < b'
run_test 'echo test > b ; rm b ; echo test add >> b ; cat < b'
run_test 'echo test > a ; echo test2 > b ; <a >b ; cat a b'
run_test 'echo test > a ; echo test2 > b ; >a >b <error; cat a b'
run_test 'echo test > a ; echo test2 > b ; rm a ; rm b ; >a >b <error; cat a b'
run_test 'echo test > a ; echo test2 > b ; >a <error b; cat a b'
run_test 'echo test > a ; echo test2 > b ; rm a ; rm b ; >a <error >b ; cat a b'
run_test 'cat <error'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; >test_files/a >test_files/b <error; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; rm test_files/a ; rm test_files/b ; >test_files/a >test_files/b <error; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; >test_files/a <error >test_files/b; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; rm test_files/a ; rm test_files/b ; >test_files/a <error >test_files/b ; cat test_files/a test_files/b'
run_test 'cat <test_files/error'
run_test 'echo test > ../a ; echo test2 > ../b ; >../a >../b <error ; cat ../a ../b'
run_test 'echo test > ../a ; echo test2 > ../b ; rm ../a ; rm ../b ; >../a >../b <error; cat ../a ../b'
run_test 'echo test > ../a ; echo test2 > ../b ; >../a <error >../b ; cat ../a ../b'
run_test 'echo test > ../a ; echo test2 > ../b ; rm ../a ; rm ../b ; >../a <error >../b ; cat ../a ../b'
run_test 'cat <../error'
run_test '<error'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; >test_files/a >>test_files/b <error; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; >>test_files/a >test_files/b <error; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; >>test_files/a >>test_files/b <error; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; >test_files/a <error >>test_files/b ; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; >test_files/a <error >>test_files/b ; cat test_files/a test_files/b'
run_test 'echo test > test_files/a ; echo test2 > test_files/b ; <error >>test_files/a >>test_files/b ; cat test_files/a test_files/b'
delete_file "test_files/a test_files/b"
run_test 'echo test > test_files/a ; echo lala > test_files/b ; >test_files/a >>test_files/b <error; cat test_files/a test_files/b'
delete_file "test_files/a test_files/b"
run_test 'echo test > test_files/a ; echo lala > test_files/b ; >>test_files/a >>test_files/b <error; cat test_files/a test_files/b'
delete_file "test_files/a test_files/b"
run_test '>test_files/a <error >>test_files/b ; cat test_files/a test_files/b'
delete_file "test_files/a test_files/b"
run_test '>test_files/a <error >>test_files/b ; cat test_files/a test_files/b'
delete_file "test_files/a test_files/b"
run_test '<error >>test_files/a >>test_files/b ; cat test_files/a test_files/b'
run_test 'echo lala > a >> a >> a ; echo test >> a ; cat < a'
run_test 'echo lala > a >> a >> a ; echo test >> a ; echo lala > a >> a >> a ; cat < a'
run_test 'echo lala >> a >> a > a ; echo test >> a ; cat < a'
run_test 'echo lala >> a >> a > a ; echo test >> a ; echo lala >> a >> a > a ; cat < a'
run_test 'echo test > a ; echo lala >> a >> a >> a ; echo test >> a ; cat < a'
run_test 'echo test > a ; echo lala >> a >> a >> a ; echo test >> a ; echo lala >> a >> a >> a ; cat < a'
run_test 'echo test > a ; echo lala > b ; rm b ; >>a >>b <error; cat a b'
run_test 'echo test > a ; echo lala > b ; rm b ; >>a <error >> b ; cat a b'
run_test 'echo test > a ; echo lala > b ; rm a ; rm b ; >>a >>b <error; cat a b'
run_test 'echo test > a ; echo lala > b ; rm a ; rm b ; >>a <error >> b ; cat a b'
run_test 'echo <a <b'
run_test 'echo <b <a'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala > a > b > a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala > a > b > a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala > a >> b > a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala > a >> b > a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala > a > b >> a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala > a > b >> a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala >> a > b > a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala >> a > b > a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala >> a >> b >> a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala >> a >> b >> a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala > a > b > a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala > a > b > a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala > a >> b > a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala > a >> b > a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala > a > b >> a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala > a > b >> a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala >> a > b > a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala >> a > b > a ; cat a b'
run_test 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala >> a >> b >> a ; cat a b'
run_test 'echo test > a ; echo test > b ; echo lala >> a >> b >> a ; cat a b'
rm -rf test_files


#$?
run_test 'export a ; echo $?'
run_test 'export % ; echo $?' 
echo "test" > a && run_test 'cat a ; echo $?' && rm a
run_test 'cat a ; echo $?'
run_test 'pwd ; echo $?'
run_test 'export a | echo $?'
run_test 'echo lala ; echo $?'
run_test 'echo lala | echo $?'
run_test 'pwd ; echo $?'
run_test 'pwd | echo $?'
run_test 'cd / ; echo $?'
run_test ' cd / | echo $?'
run_test 'cd ~/ ; echo $?'
run_test ' cd ~/ | echo $?'
run_test 'cd /error ; echo $?'
run_test 'cd ~/error ; echo $?'
run_test 'export a ; unset a ; echo $?'
run_test 'export a | unset a | echo $?'
run_test 'unset a ; echo $?'
run_test 'unset a | echo $?'
run_test 'echo $? ; echo $? ; echo $?'
run_test 'echo $? | echo $? | echo $?'
run_test 'cd error ; echo $?'
run_test 'cd error error ; echo $?'
run_test './error ; echo $?'
run_test '<error ; echo $?'
run_test 'cat <error ; echo $?'
run_test 'cat < ; echo $?'
run_test 'echo test > ; echo $?'
run_test 'echo test >> ; echo $?'

#PROGRAM
run_test './prog'
run_test './prog a'
run_test './prog a b'
run_test './prog a b c'
run_test '$PWD/prog'
run_test '$PWD/prog a'
run_test '$PWD/prog b'
mkdir test_prog
run_test 'cd test_prog ; ../prog'
run_test 'cd test_prog ; ../prog a'
run_test 'cd test_prog ; ../prog a b'
rm -rf test_prog


#OTHERS
run_test 'touch test_file ; rm test_file'
run_test 'ls'
run_test 'cat bible.txt'
run_test '/bin/ls'
run_test 'echo test > a ; /bin/cat a'
run_test 'echo test > a ; /bin/rm a'
run_test '/bin/pwd'
run_test 'unset PATH ; ls ; cd /bin ; ls'
run_test 'export PATH=$PWD/add_path:$PATH ; export | grep PATH ; ls'




#EMPTY ENV
echo 'export' | env -i ../minishell | grep -v _= > diff_minishell.txt
echo 'export' | env -i bash | grep -v _= > diff_bash.txt
diff --text diff_minishell.txt diff_bash.txt > /dev/random 2>&1
result=$?
if [ $result = 0 ]
then
    echo -e "$GREEN TEST $test_number ✓$RESET"
elif [ $result = 1 ]
then
    echo -e "$RED\n======================== TEST $test_number ✗ ========================$RESET"
    echo -ne "\033[38;5;90mCommand :$RESET"
    echo $1

    echo -e "$GREY\nMinishell output\n-------------------------------------------------------------$RESET"
    diff --text diff_minishell.txt diff_bash.txt | grep '<' | cut -c 2-
    echo -e "$GREY-------------------------------------------------------------$RESET"

    echo -e "$ORANGE\nBash output\n-------------------------------------------------------------$RESET"
    diff --text diff_minishell.txt diff_bash.txt | grep '>' | cut -c 2-
    echo -e "$ORANGE-------------------------------------------------------------\n$RESET"
fi




echo -e "$WHITE\n\nTest not mandatory commands ? [$GREEN Y$WHITE /$RED N $WHITE]$RESET"
echo -ne "$CYAN>> $RESET"
read user_input
if [ $user_input = 'Y' ]
then
    echo -e "\n\n$ORANGE#############################################################################"
    echo -e "#             NOT MANDATORY TO BE SIMILAR BUT MUST NOT SEGFAULT             #"
    echo -e "#############################################################################$RESET\n"

    run_test 'echo $!'
    run_test 'echo $@'
    run_test 'echo $#'
    run_test 'echo $%'
    run_test 'echo $^'
    run_test 'echo $&'
    run_test 'echo $*'
    run_test 'echo $('
    run_test 'echo $)'
    run_test 'echo $()'
    run_test 'echo $-'
    run_test 'echo $+'
    run_test 'echo ${'
    run_test 'echo $}'
    run_test 'echo ${}'
    run_test 'echo $['
    run_test 'echo $]'
    run_test 'echo $[]'
    run_test "echo \'\"\'"
    run_test "echo \'\"\'\""
    run_test "echo \'\"\'\"|\""
    run_test "echo \'\"\'\"|\"\'||\'"
    run_test "echo \'\"\'\"|\"\'\|\|\'"
    run_test "echo \'\"\'\"|\"\'\|\|\' \'\' \"\""
    run_test 'echo "\\\"\\'
    run_test "echo \\'\"\'"
    run_test "echo \'\\"\'\\"|\"\'\|\|\' \'\' \"\""
fi


echo -e "\n\n$PURPLE#############################################################################"
echo -e "#                            RETURN VALUE TESTS                             #"
echo -e "#############################################################################$RESET\n"
let "test_number=1"

run_return 'exit'
run_return 'exit | echo lala'
run_return 'exit ; echo lala'
run_return 'exit 0'
run_return 'exit 1'
run_return 'exit 255'
run_return 'exit 256'
run_return 'exit 1000'
run_return 'exit 9223372036854775807'
run_return 'exit +0'
run_return 'exit +1'
run_return 'exit +255'
run_return 'exit +256'
run_return 'exit +1000'
run_return 'exit +9223372036854775807'
run_return 'exit -0'
run_return 'exit -1'
run_return 'exit -255'
run_return 'exit -256'
run_return 'exit -1000'
run_return 'exit -9223372036854775808'
run_return 'exit --1'
run_return 'exit ++1'
run_return 'exit ++1'
run_return 'exit lala'
run_return 'exit ?'
run_return 'exit @@'
run_return 'exit 9223372036854775810'
run_return 'exit -9223372036854775810'
run_return 'export a ; exit $a'
run_return 'export a= ; exit $a'
run_return 'export a=77 ; exit $a'
run_return 'export % ; exit $?'
run_return 'exit $a'
run_return 'exit 55 55'
run_return 'exit +55 55'
run_return 'exit -55 55'
run_return 'exit lala lala'
run_return 'exit 55 lala'
run_return 'exit lala 55'


echo -e "$WHITE\n\nTest leaks ? [$GREEN Y$WHITE /$RED N $WHITE]$RESET"
echo -ne "$CYAN>> $RESET"
read user_input
if [ $user_input != 'Y' ]
then
    rm -rf add_path test_cd ~/test_cd test_files ../minishell.dSYM
    delete_file "a b ../a ../b buffer ../buffer buffer2 prog diff_minishell.txt diff_bash.txt ../diff_minishell.txt ../diff_bash.txt leaks_minishell.txt boucle"
    exit
fi

echo -e "\n\n$ORANGE#############################################################################"
echo -e "#                               LEAKS TESTS                                 #"
echo -e "#############################################################################$RESET\n"
let "test_number=1"

run_leaks 'echo test'
run_leaks 'echo echo'
run_leaks 'echo'
run_leaks 'echo -n -n lala'
run_leaks 'echo $PWD'
run_leaks 'echo $OLDPWD'
run_leaks 'echo \$PWD'
run_leaks 'echo \\$PWD'
run_leaks "echo lala ;   echo   test     ;echo      lala"
run_leaks "echo lala             |echo       test |                            echo  lala"
run_leaks "echo lala ;   echo test| echo        lala"

run_leaks 'pwd ; echo $PWD ; echo OLDPWD ; unset PWD ; echo $PWD ; echo $OLDPWD ; cd .. ; echo $OLDPWD ; pwd ; echo $OLDPWD ; cd .. ; pwd ; echo $OLDPWD'

run_leaks 'export testvar= ; env | grep -a testvar'
run_leaks 'export testvar=@lala ; env | grep -a testvar'
run_leaks 'export _testvar=10 ; env | grep -a _testvar'
run_leaks 'export _testvar10 ; env | grep -a _testvar10'
run_leaks 'export'

run_leaks 'pwd'
run_leaks 'pwd test'
run_leaks 'pwd test lala'
run_leaks 'pwd "test"'

run_leaks 'export a=?lala%lala; export ; unset a ; export'
run_leaks 'export a=a10a10 ; export ; unset a ; export'
run_leaks 'export a10 ; export ; unset a10 ; export'
run_leaks 'export a10= ; export ; unset a10 ; export'
run_leaks 'export a10=10 ; export ; unset a10 ; export'
run_leaks 'export a10=lala ; export ; unset a10 ; export'
run_leaks 'export a10=?lala%lala; export ; unset a10 ; export'
run_leaks 'export a10=a10a10 ; export ; unset a10 ; export'

mkdir test_cd
mkdir ~/test_cd
run_leaks 'pwd ; cd ; pwd'
run_leaks 'pwd ; cd .. ; pwd'
export dir=${PWD%/*} && run_leaks 'pwd ; cd $dir ; pwd' && unset dir
run_leaks 'pwd ; cd test_cd ; pwd'
run_leaks 'pwd ; cd ~/ ; pwd'
run_leaks 'pwd ; cd ~/test_cd ; pwd'
run_leaks 'pwd ; cd .. ; pwd ; cd .. ; pwd ; cd ~/ ; pwd'
run_leaks 'pwd ; cd /'
run_leaks 'pwd ; cd error ; pwd'
run_leaks 'pwd ; cd error error ; pwd'
run_leaks 'pwd ; cd test_cd error ; pwd'
run_leaks 'pwd ; cd error test_cd error ; pwd'
run_leaks 'pwd ; cd ~/test_cd error ; pwd'
run_leaks 'pwd ; cd error ~/test_cd error ; pwd'
echo -e "\n$ORANGE >> THOSE TESTS MAY HAVE TO BE CHANGED BY A DIFFERENT PATH $RESET"
run_leaks 'pwd ; cd ../../../Bureau/../Bureau/../Bureau ; pwd'
run_leaks 'pwd ; cd ./../../../Bureau/../Bureau/../Bureau ; pwd'
run_leaks 'pwd ; cd ./../../../Bureau/././././../Bureau/././././../Bureau ; pwd'
run_leaks 'pwd ; cd ~/../home/../home/Bureau/../Bureau/../Bureau ; pwd'
run_leaks 'pwd ; cd ~/.. ; pwd'
run_leaks 'pwd ; cd ../.. ; cd minishell/../minishell/.. ; pwd'
run_leaks 'pwd ; cd ../../ ; cd ./minishell/.././minishell/../. ; pwd'
run_leaks 'pwd ; cd ~ ; cd ../../../../../ ; pwd'
run_leaks 'pwd ; cd ../.../ ; pwd'
run_leaks 'pwd ; cd ../... ; pwd'
mkdir ...
run_leaks 'pwd ; cd ... ; pwd'
run_leaks 'pwd ; cd ../minishell_tester/... ; pwd'
run_leaks 'pwd ; cd .../../..././././../... ; pwd'
rm -rf ~/test_cd test_cd ...

run_leaks 'exit'
run_leaks 'exit | echo lala'
run_leaks 'exit ; echo lala'
run_leaks 'exit 0'
run_leaks 'exit 1'
run_leaks 'exit 255'
run_leaks 'exit 256'
run_leaks 'exit 1000'
run_leaks 'exit 9223372036854775807'
run_leaks 'exit +0'
run_leaks 'exit +1'
run_leaks 'exit +255'
run_leaks 'exit +256'
run_leaks 'exit +1000'
run_leaks 'exit +9223372036854775807'
run_leaks 'exit -0'
run_leaks 'exit -1'
run_leaks 'exit -255'
run_leaks 'exit -256'
run_leaks 'exit -1000'
run_leaks 'exit -9223372036854775808'
run_leaks 'exit --1'
run_leaks 'exit ++1'
run_leaks 'exit ++1'
run_leaks 'exit lala'
run_leaks 'exit ?'
run_leaks 'exit @@'
run_leaks 'exit 9223372036854775810'
run_leaks 'exit -9223372036854775810'
run_leaks 'export a ; exit $a'
run_leaks 'export a= ; exit $a'
run_leaks 'export a=77 ; exit $a'
run_leaks 'export % ; exit $?'
run_leaks 'exit $a'
run_leaks 'exit 55 55'
run_leaks 'exit +55 55'
run_leaks 'exit -55 55'
run_leaks 'exit lala lala'
run_leaks 'exit 55 lala'
run_leaks 'exit lala 55'


run_leaks 'export test=lala ; echo $test ; export $test=10 ; echo $lala'
run_leaks 'export test=lala ; export $test=a10 ; export $lala=test ; unset $lala ; export' 'grep -v _='
run_leaks 'export a b c ; unset a c ; export' 'grep -v _='
run_leaks 'export test=echo val=lala ; $test $lala ; export' 'grep -v _='

run_leaks 'export a | echo lala ; export' 'grep -v _='
run_leaks 'export | echo lala'
run_leaks 'unset PWD | echo lala ; export' 'grep -v _='
run_leaks 'cd .. | echo lala ; export' 'grep -v _='
run_leaks 'echo test | echo lala'
run_leaks 'pwd | echo lala'
run_leaks 'env | echo lala'
run_leaks 'cat bible.txt | grep testifieth'
run_leaks 'echo test | cat | cat | cat | cat | cat | grep test'

mkdir test_files
run_leaks 'echo test > a ; cat < a'
run_leaks 'echo lala >a ; cat <a'
run_leaks 'echo test > test_files/a ; cat < test_files/a'
run_leaks 'echo lala >test_files/a ; cat <test_files/a'
run_leaks 'echo test > b ; echo test add >> b ; cat < b'
run_leaks 'echo test > b ; rm b ; echo test add >> b ; cat < b'
run_leaks 'echo test > a ; echo test2 > b ; <a >b ; cat a b'
run_leaks 'echo test > test_files/a ; echo test2 > test_files/b ; rm test_files/a ; rm test_files/b ; >test_files/a >test_files/b <error; cat test_files/a test_files/b'
run_leaks 'echo test > test_files/a ; echo test2 > test_files/b ; >test_files/a <error >test_files/b; cat test_files/a test_files/b'
run_leaks 'echo lala > a >> a >> a ; echo test >> a ; cat < a'
run_leaks 'echo lala > a >> a >> a ; echo test >> a ; echo lala > a >> a >> a ; cat < a'
run_leaks 'echo lala >> a >> a > a ; echo test >> a ; cat < a'
run_leaks 'echo lala > a ; rm a ; echo lala > b ; rm b ; echo lala >> a >> b >> a ; cat a b'
run_leaks 'echo test > a ; echo test > b ; echo lala >> a >> b >> a ; cat a b'
run_leaks 'echo <b <a'
run_leaks 'echo test        >a ; cat<        a'
run_leaks 'echo lala            >     a ; cat        <       a'
rm -rf test_files

run_leaks 'export a ; echo $?'
run_leaks 'export % ; echo $?'

run_leaks './prog a b'
run_leaks './prog a b c'
run_leaks '$PWD/prog'

run_leaks 'touch test_file ; rm test_file'
run_leaks 'ls'

################ END SHELL ################
rm -rf add_path test_cd ~/test_cd test_files ../minishell.dSYM ...
delete_file "a b ../a ../b buffer ../buffer buffer2 prog diff_minishell.txt diff_bash.txt ../diff_minishell.txt ../diff_bash.txt leaks_minishell.txt boucle"

