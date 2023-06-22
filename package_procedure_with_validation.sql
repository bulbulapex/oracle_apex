create or replace PACKAGE PKG_COA IS
	PROCEDURE INSERT_COA(
		P_ACC_HEAD IN VARCHAR2,
		P_ACC_CTRL IN CHAR,
        PO_ERROR   OUT VARCHAR2,
        PO_ER_TYPE OUT VARCHAR2
	);
    PROCEDURE ADD_CHILD(
        P_ACC_HEAD IN VARCHAR2,
        P_ACC_COA_ID IN NUMBER,
        P_ACC_CTRL IN CHAR,
        PO_ERROR OUT VARCHAR2
    );
END PKG_COA;
/

create or replace PACKAGE BODY PKG_COA IS
	PROCEDURE INSERT_COA(
		P_ACC_HEAD IN VARCHAR2,
		P_ACC_CTRL IN CHAR,
        PO_ERROR   OUT VARCHAR2,
        PO_ER_TYPE OUT VARCHAR2
	)
    IS
        ACC_HEAD_EXP  EXCEPTION;
        V_ACC_CODE NUMBER;
        V_ACC_HEAD_LBL NUMBER DEFAULT 1;
    BEGIN

        IF P_ACC_HEAD IS NULL
        THEN
            RAISE ACC_HEAD_EXP;
        END IF;
        
        

        IF V_ACC_HEAD_LBL = 1
        THEN   
            SELECT NVL(MAX(ACC_CODE), 0) + 1
            INTO V_ACC_CODE
            FROM ACC_COA
            WHERE ACC_HEAD_LBL = 1;
        ELSE
            V_ACC_CODE := NULL;
        END IF;

        IF V_ACC_HEAD_LBL = 1
        THEN
            INSERT INTO ACC_COA(
                    ACC_CODE,
                    ACC_HEAD,
                    ACC_CTRL,
                    ACC_HEAD_LBL,
                    ACC_PARENT_ID,
                    ACC_COMP_ID,
                    ACC_EXTRA_CODE
                    )
            VALUES(
                    V_ACC_CODE,
                    P_ACC_HEAD,
                    P_ACC_CTRL,
                    V_ACC_HEAD_LBL,
                    NULL,
                    NULL,
                    NULL
            );
        ELSE
            PO_ERROR := 'NOT MAIN CATEGORY!';
            PO_ER_TYPE := NULL;
        END IF;


        IF PO_ERROR IS NULL
        THEN
            COMMIT;
            PO_ERROR := '1';
        ELSE
            ROLLBACK;
        END IF;
        
        /*
        DECLARE
            V_ERROR   VARCHAR2 (200);
        BEGIN
            INSERT_COA (P_ACC_HEAD          => '',
                          P_ACC_CTRL       => 'N'
                          PO_ERROR            => V_ERROR);
            DBMS_OUTPUT.PUT_LINE (V_ERROR);
        END;*/

    EXCEPTION
        WHEN ACC_HEAD_EXP
        THEN
            PO_ERROR := 'Account Head must be entry value';
            PO_ER_TYPE := 'P_ACC_HEAD';
    END INSERT_COA;

    PROCEDURE ADD_CHILD(
        P_ACC_HEAD IN VARCHAR2,
        P_ACC_COA_ID IN NUMBER,
        P_ACC_CTRL IN CHAR,
        PO_ERROR OUT VARCHAR2
    )
    IS
        V_ACC_CODE NUMBER;
        V_ACC_HEAD_LBL NUMBER;
        V_GNRT_ACC_CODE VARCHAR2(50);
        V_TOT_CHILD NUMBER;
    BEGIN

        SELECT ACC_HEAD_LBL, ACC_CODE
        INTO V_ACC_HEAD_LBL, V_ACC_CODE
        FROM ACC_COA
        WHERE ACC_COA_ID = P_ACC_COA_ID;

        SELECT COUNT(*) + 1
        INTO V_TOT_CHILD
        FROM ACC_COA
        WHERE ACC_PARENT_ID = P_ACC_COA_ID;

        IF V_ACC_HEAD_LBL = 1
        THEN   
            V_GNRT_ACC_CODE := V_ACC_CODE||''||V_TOT_CHILD;
        ELSE
            V_GNRT_ACC_CODE := V_ACC_CODE||''||LPAD( V_TOT_CHILD, 2, '0' );
        END IF;

        INSERT INTO ACC_COA(
                ACC_CODE,
                ACC_HEAD,
                ACC_CTRL,
                ACC_HEAD_LBL,
                ACC_PARENT_ID,
                ACC_COMP_ID,
                ACC_EXTRA_CODE
                )
        VALUES(
                TO_NUMBER(V_GNRT_ACC_CODE),
                P_ACC_HEAD,
                P_ACC_CTRL,
                V_ACC_HEAD_LBL + 1,
                P_ACC_COA_ID,
                NULL,
                NULL
        );
    END ADD_CHILD;
END PKG_COA;
/



----oracle apex uses this---
create process: INSERT_COA
DECLARE
    V_ER_TYPE    VARCHAR2(500);
    V_ERROR      VARCHAR2(500);
    E_ERROR      EXCEPTION;
BEGIN

    PKG_COA.INSERT_COA(
		P_ACC_HEAD => :P2_ACC_HEAD,
		P_ACC_CTRL => :P2_ACC_CTRL,
        PO_ERROR   => V_ERROR,
        PO_ER_TYPE => V_ER_TYPE
	);
    IF V_ERROR='1' THEN
        apex_application.g_print_success_message :='<span style="blue">'||'Saved'|| '</span>';
    ELSE
        IF V_ER_TYPE = 'P_ACC_HEAD'
        THEN
            apex_error.add_error (
                    p_message          => V_ERROR,
                    --p_display_location => apex_error.c_inline_in_notification,
                    p_display_location => apex_error.c_inline_with_field_and_notif,
                    --p_display_location => apex_error.c_inline_with_field,
                    --p_display_location => apex_error.c_on_error_page,
                    p_page_item_name    => 'P2_ACC_HEAD' );
        ELSIF V_ER_TYPE IS NULL
        THEN
            apex_util.set_session_state('P2_ERROR_MSG', V_ERROR);
            /*when use this type of set session state then you have create a hidden item P2_ERROR_MSG and place it in process error -> error message &P2_ERROR_MSG. */
            RAISE E_ERROR;
        END IF;
    END IF;
END;
