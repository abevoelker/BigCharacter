
 /*------------------------------------------------------------------------
    File        : BigCharacter.cls
    Purpose     : Mimics LONGCHAR, but removes performance penalties.
    Author(s)   : Abe Voelker
    Created     : Mon Oct 04 19:45:25 CDT 2010
    Notes       : * This version can run out of stack space for very
                    large amounts of data ("increase -s" error messages).
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS BigCharacter USE-WIDGET-POOL:

    &SCOPED-DEFINE TT_CHARACTER_MAX       31977
    &SCOPED-DEFINE CHARACTER_DATATYPE_MAX 31991

    DEFINE PRIVATE VARIABLE iNumBlocks    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE iTotBlockSize AS INT64   NO-UNDO. /* The total size of all blocks, in bytes */

	DEFINE PRIVATE TEMP-TABLE ttChar NO-UNDO
      FIELD iPK         AS INTEGER
      FIELD cData       AS CHARACTER
      FIELD iDataLength AS INTEGER
      INDEX IXPK IS PRIMARY UNIQUE iPK.
		
	CONSTRUCTOR PUBLIC BigCharacter ():
		SUPER ().
		CREATE ttChar.
	END CONSTRUCTOR.
	
    METHOD PUBLIC VOID empty():
	    EMPTY TEMP-TABLE ttChar NO-ERROR.
	    CREATE ttChar.
	    ASSIGN iNumBlocks    = 0
               iTotBlockSize = 0.
	END METHOD.
    
	METHOD PUBLIC VOID append(INPUT ipc AS CHARACTER):
        DEF VAR iAvailSpace AS INTEGER NO-UNDO.
        FIND LAST ttChar.
        iAvailSpace = {&TT_CHARACTER_MAX} - ttChar.iDataLength.
	    
        IF LENGTH(ipc) GT iAvailSpace THEN DO:
            /* If there is some space available in the last block, then fill it */
            IF iAvailSpace GT 0 THEN DO:
                ASSIGN ttChar.cData       = ttChar.cData + SUBSTRING(ipc, 1, iAvailSpace)
                       ttChar.iDataLength = LENGTH(ttChar.cData)
                       iTotBlockSize      = iTotBlockSize + LENGTH(SUBSTRING(ipc, 1, iAvailSpace))
                       ipc                = SUBSTRING(ipc, iAvailSpace + 1).
            END.
            /* The last block has been filled and we need more space, so allocate a new block */
            newBlock().
            append(ipc). /* Recursion, baby! */
        END.
        ELSE DO:
            ASSIGN ttChar.cData       = ttChar.cData + ipc
                   ttChar.iDataLength = ttChar.iDataLength + LENGTH(ipc)
                   iTotBlockSize      = iTotBlockSize + LENGTH(ipc).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID append(INPUT iplc AS LONGCHAR):
        /* Break the LONGCHAR into CHARACTER data, and send to that method */
        DEF VAR i AS INT NO-UNDO.
        DO WHILE i LT LENGTH(iplc):
            THIS-OBJECT:append(STRING(SUBSTRING(iplc, i + 1, {&CHARACTER_DATATYPE_MAX}))).
            i = i + {&CHARACTER_DATATYPE_MAX}.
        END.
    END METHOD.
    
    METHOD PUBLIC VOID setValue(INPUT ipcString AS CHARACTER):
        THIS-OBJECT:empty().
        THIS-OBJECT:append(ipcString).
    END.
    
    METHOD PUBLIC VOID setValue(INPUT iplcString AS LONGCHAR):
        THIS-OBJECT:empty().
        THIS-OBJECT:append(iplcString).
    END.
    
	METHOD PUBLIC INTEGER indexOf(INPUT ipcString   AS CHARACTER):
	    RETURN INDEX(THIS-OBJECT:toLongchar(), ipcString).
	END METHOD.
	
	METHOD PUBLIC INTEGER indexOf(INPUT ipcString   AS CHARACTER,
	                              INPUT ipiStarting AS INTEGER):
	    RETURN INDEX(THIS-OBJECT:toLongchar(), ipcString, ipiStarting).
	END METHOD.
    
	METHOD PUBLIC LONGCHAR substr(INPUT ipiPosition AS INTEGER):
	    RETURN SUBSTRING(THIS-OBJECT:toLongchar(), ipiPosition).
	END.
	
	METHOD PUBLIC LONGCHAR substr(INPUT ipiPosition AS INTEGER,
	                              INPUT ipiLength   AS INTEGER):
	    RETURN SUBSTRING(THIS-OBJECT:toLongchar(), ipiPosition, ipiLength).
	END.
    
    METHOD PUBLIC LONGCHAR toLongchar():
        DEFINE VARIABLE oplc AS LONGCHAR NO-UNDO.
        FOR EACH ttChar:
          oplc = oplc + ttChar.c.
        END.
        RETURN oplc.
    END METHOD.
    
    METHOD PRIVATE VOID newBlock():
        iNumBlocks = iNumBlocks + 1.
        CREATE ttChar.
        ttChar.iPK = iNumBlocks.
    END METHOD.
    
    METHOD PUBLIC INT64 size():
        RETURN iTotBlockSize.
    END.

END CLASS.