Type: select2
Select List Type: multivalue select list
list of value query: SELECT CL_NAME_ENG DES, CL_ID RET
                      FROM CAT_LICENCE
                      ORDER BY 1 ASC;

Now source theke -> type : sql query (return colon separate value)
SELECT CAT_LICENCE
FROM CONT_PROFILE
WHERE CONT_ID = :P112_CONT_ID;
used: always, replacing any existing value in session state
maintain session: per session disk.

data insert hobe '1:2:3'  eyvabe select2 plugin er multivalue select korle
