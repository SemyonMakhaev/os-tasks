#!/bin/bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo Игра \"Крестики-нолики\"
    echo "Запуск: ./cross.sh [-h] [--help]"
    echo Играем на клавишах q w e - a s d - z x c
    echo
    echo " Q | W | E "
    echo "---+---+---"
    echo " A | S | D "
    echo "---+---+---"
    echo " Z | X | C "
    echo
    echo "(с) Семён Махаев, КБ-401"
    exit 0
fi

fifo1=pipe1
fifo2=pipe2
empty=" "

game=( " " " " " " " " " " " " " " " " " ")

declare -A numbers=( ["q"]="0" ["w"]="1" ["e"]="2" ["a"]="3" ["s"]="4" ["d"]="5" ["z"]="6" ["x"]="7" ["c"]="8")

function redraw() {
    # Перерисовка

    clear
    echo " ${game[0]} | ${game[1]} | ${game[2]} "
    echo "---+---+---"
    echo " ${game[3]} | ${game[4]} | ${game[5]} "
    echo "---+---+---"
    echo " ${game[6]} | ${game[7]} | ${game[8]} "
    if [[ $bad_move == 1 ]]; then
        echo "Плохо сходил, подумай ещё"
    fi
}

function check_rows() {
    # Проверяет строки на совпадение знаков

    if [[ ! "${game[0]}" == " " && ${game[0]} == ${game[1]} && ${game[1]} == ${game[2]} ]]; then
        determine_winner ${game[0]}
        return 0
    fi
    if [[ ! "${game[3]}" == " " && ${game[3]} == ${game[4]} && ${game[3]} == ${game[5]} ]]; then
        determine_winner ${game[3]}
        return 0
    fi
    if [[ ! "${game[6]}" == " " && ${game[6]} == ${game[7]} && ${game[7]} == ${game[8]} ]]; then
        determine_winner ${game[6]}
        return 0
    fi

    return 1
}

function check_columns() {
    # Проверяет столбцы на совпадение знаков

    if [[ ! "${game[0]}" == " " && ${game[0]} == ${game[3]} && ${game[3]} == ${game[6]} ]]; then
        determine_winner ${game[0]}
        return 0
    fi
    if [[ ! "${game[1]}" == " " && ${game[1]} == ${game[4]} && ${game[4]} == ${game[7]} ]]; then
        determine_winner ${game[1]}
        return 0
    fi
    if [[ ! "${game[2]}" == " " && ${game[2]} == ${game[5]} && ${game[5]} == ${game[8]} ]]; then
        determine_winner ${game[2]}
        return 0
    fi

    return 1
}

function check_diagonals() {
    # Проверяет диагонали на совпадение знаков

    if [[ ! "${game[0]}" == " " && ${game[0]} == ${game[4]} && ${game[4]} == ${game[8]} ]]; then
        determine_winner ${game[0]}
        return 0
    fi
    if [[ ! "${game[2]}" == " " && ${game[2]} == ${game[4]} && ${game[4]} == ${game[6]} ]]; then
        determine_winner ${game[2]}
        return 0
    fi

    return 1
}

function play() {
    # Проверка текущего состояния игры

    check_rows
    rows_result=$?
    check_columns
    columns_result=$?
    check_diagonals
    diagonals_result=$?


    if [[ $rows_result == 0 || $columns_result == 0 || $diagonals_result == 0 ]]; then
        main_loop=0
        return 0
    fi

    length=${#game[*]}
    for (( i=0; i<$(( $length )); i++ )); do
        if [[ "${game[$i]}" == " " ]]; then
            return 0
        fi
    done

    echo "Ничья"
    main_loop=0
}

function determine_winner() {
    # Определение победителя по окончанию игры
    # $1 - знак победителя, X или O

    if [[ $player_number == 1 && "$1" == "X" ]] || [[ $player_number == 0 && "$1" == "O" ]]; then
        echo "Победа!"
    else
        echo "Ты проиграл"
    fi
}

function is_correct_input() {
    # Проверка на корректность ввода
    # $1 - ввод

    num="${numbers[$1]}"
    if [[ $1 =~ ^[qweasdzxc]{1}$ && "${game[$num]}" == " " ]]; then
        bad_move=0
    else
        bad_move=1
    fi
}

function read_game() {
    # Считывание игрового состояния из файла

    input=$(cat $read_file)
    prev=$input

    while [[ $input == $prev ]]; do
        input=$(cat $read_file)
    done

    if [[ $input == "start" ]]; then
        return 0
    fi

    IFS=',' read -r -a splited <<< "$input"

    length=${#splited[*]}
    idx=0
    for (( i=1; i<$length; i++ )); do
        game[$idx]="${splited[$i]}"
        idx=$(( $idx+1 ))
    done
}

function write_game() {
    # Запись игрового состояния

    state=""
    length=${#game[*]}
    for (( i=0; i<$length; i++ )); do
        state="${state},${game[$i]}"
    done
    echo $state > $write_file &
}

function clear_dir() {
    # Удаляет файлы

    rm $fifo1 $fifo2 >/dev/null 2>&1
}

function loop() {
    # Основной цикл

    while [[ $main_loop == 1 ]]; do
        if [[ $current_move == 1 ]]; then
            read -p "Твой ход " input
            is_correct_input $input
            if [[ $bad_move == 0 ]]; then
                number="${numbers[$input]}"
                if [[ $player_number == 1 ]]; then
                    game[$number]="X"
                else
                    game[$number]="O"
                fi
                write_game
                current_move=0
            fi
        else
            echo "Ход другого игрока"
            read_game
            current_move=1
        fi
        redraw
        play
    done
}

if [[ ! -f $fifo1 || ! -f $fifo2 ]]; then
    clear_dir
    touch $fifo1
    touch $fifo2
    player_number=1
    current_move=1
    read_file=$fifo1
    write_file=$fifo2
    echo Ты за X
else
    player_number=0
    current_move=0
    read_file=$fifo2
    write_file=$fifo1
    echo Ты за O
fi

echo Играем на клавишах q w e - a s d - z x c
echo Ожидание подключения...
echo "start" > $write_file

res=$(cat $read_file)
while [[ "$res" != "start" ]]; do
    res=$(cat $read_file)
done

bad_move=0
main_loop=1

redraw
loop
clear_dir
