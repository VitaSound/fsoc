\ tests/futils_iomap_check_test.4th — обёртка fmix для tests/futils/iomap_check_test.4th
\ fmix test сканирует каталог tests/ нерекурсивно (test-read-dir в fmix_test.4th),
\ поэтому тесты из tests/futils/ без обёртки не запускаются ни в fmix test,
\ ни в pre-commit/pre-push. Обёртка лишь включает настоящий тест.
s" futils/iomap_check_test.4th" included
