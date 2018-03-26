#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#define SIZE 2048

unsigned char buffer[SIZE];

void writeBytes(int fileDescriptor, int readBytesCount) {
    int writeBytesCount = 0;
    int seekBytesCount = 0;
    unsigned char* readIdx = buffer;
    unsigned char* writeIdx = buffer;

    for (int i = readBytesCount; i > 0; i--) {
        int currentByte = *readIdx;

        if (currentByte == '\0') {
            // Текущий байт нулевой
            if (seekBytesCount == 0 && writeBytesCount > 0) {
                // Начали считывать последовательность нулей
                // Записываем накопленную ненулевую часть в файл
                write(fileDescriptor, writeIdx, writeBytesCount);
                writeBytesCount = 0;
            }

            seekBytesCount++;
        } else {
            // Текущий байт ненулевой
            if (seekBytesCount > 0) {
                // Закончили считывать последовательность нулей
                // Пропускаем её
                lseek(fileDescriptor, seekBytesCount, SEEK_CUR);
                writeIdx = readIdx;
                seekBytesCount = 0;
            }

            writeBytesCount++;
        }

        readIdx++;
    }

    if (seekBytesCount > 0) {
        lseek(fileDescriptor, seekBytesCount, SEEK_CUR);
    } else if (writeBytesCount > 0) {
        write(fileDescriptor, writeIdx, writeBytesCount);
    }
}

int sparse(char* filename) {
    int fileDescriptor = open(filename, O_WRONLY | O_TRUNC | O_CREAT, 0644);

    if (fileDescriptor == -1) {
        printf("Ошибка открытия файла");
        return 1;
    }

    int readBytesCount = read(STDIN_FILENO, buffer, SIZE);

    while (readBytesCount > 0) {
        writeBytes(fileDescriptor, readBytesCount);
        readBytesCount = read(STDIN_FILENO, buffer, SIZE);
    }

    close(fileDescriptor);

    return 0;
}

void printHelp(char* prog) {
    printf(
        "Программа SPARSE записывает файл на диск без цепочек нулей"
        "Запуск: gzip -cd sparse-file.gz | %s [filename]\n"
        "    filename - имя выходной файл\n"
        "(c) Семён Махаев, КБ-401", prog
    );
}

int main(int argc, char **argv) {
    if (argc == 2) {
        sparse(argv[1]);
    } else {
        printHelp(argv[0]);
    }
}
