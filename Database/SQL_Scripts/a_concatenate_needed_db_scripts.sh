rm -f 000__CreateALLdb.sql
cat 00* 01* 02*                > 000__CreateALLdb.sql

rm -f 06__drop_tables_create_tables_insert_test_data.sql
cat 00__* 01__* 02__*          > 06__drop_tables_create_tables_insert_test_data.sql
