# Программа Sparse

Дополнение к gzip. Пропускает цепочки нулей при разархивировании.

### Запуск:
```bash
gcc sparse.c -o sparse
gzip -cd zipped.gz | ./sparse unzipped
```
