 
 /*------------------------------------------------------------------------
    File        : CharBlock.cls
    Purpose     : Wraps blocks of CHARACTER data; used by BigCharacter
    Author(s)   : Abe Voelker
    Created     : Tue Oct 05 20:16:02 CDT 2010
    Notes       : * This class was created to get around the out of stack
                    memory ("increase -s") error messages.
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS CharBlock USE-WIDGET-POOL:

    &SCOPED-DEFINE TT_CHARACTER_MAX       31976
    &SCOPED-DEFINE CHARACTER_DATATYPE_MAX 31991

    DEFINE PRIVATE VARIABLE iNumBlocks    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE iTotBlockSize AS INT64   NO-UNDO. /* The total size of all blocks, in bytes */
    
	DEFINE PROTECTED TEMP-TABLE ttChar NO-UNDO
      FIELD iPK         AS INTEGER
      FIELD cData       AS CHARACTER
      FIELD iDataLength AS INTEGER
      INDEX IXPK IS PRIMARY UNIQUE iPK.

    /* Note: the input BigCharacter is not needed; it is simply used to */
    /* ensure that delegation only occurs from the BigCharacter class    */		
	CONSTRUCTOR PUBLIC CharBlock (INPUT ipobjBC AS BigCharacter):
		SUPER ().
		CREATE ttChar.
		ASSIGN iNumBlocks = 1
		       ttChar.iPK = iNumBlocks.
	END CONSTRUCTOR.
	
    METHOD PUBLIC VOID empty():
	    EMPTY TEMP-TABLE ttChar NO-ERROR.
	    CREATE ttChar.
	    ASSIGN iNumBlocks    = 1
               iTotBlockSize = 0
               ttChar.iPK    = iNumBlocks.
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
    
    METHOD PUBLIC VOID append(INPUT ipobjcb AS CharBlock):
        DEF VAR i AS INT NO-UNDO.
        DO i=1 TO ipobjcb:getNumBlocks():
            THIS-OBJECT:append(ipobjcb:getBlock(i)).
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
    
    METHOD PUBLIC VOID setValue(INPUT ipobjcb AS CharBlock):
        THIS-OBJECT:empty().
        THIS-OBJECT:append(ipobjcb).
    END.
    
    METHOD PUBLIC LONGCHAR toLongchar():
        DEFINE VARIABLE oplc AS LONGCHAR NO-UNDO.
        FOR EACH ttChar:
          oplc = oplc + ttChar.c.
        END.
        RETURN oplc.
    END METHOD.
    
    METHOD PUBLIC LOGICAL toFile(INPUT ipcFile   AS CHARACTER,
                                 INPUT iplAppend AS LOGICAL):
        OUTPUT TO VALUE(ipcFile) NO-CONVERT.
        FOR EACH ttChar:
            PUT UNFORMATTED ttChar.cData.
        END.
        OUTPUT CLOSE.
        RETURN TRUE.
    END METHOD.
    
    METHOD PUBLIC LOGICAL toFile(INPUT ipcFile AS CHARACTER):
        RETURN THIS-OBJECT:toFile(ipcFile, FALSE). /* Default is to clobber the old file */
    END METHOD.
    
    METHOD PRIVATE VOID newBlock():
        CREATE ttChar.
        ASSIGN iNumBlocks = iNumBlocks + 1
               ttChar.iPK = iNumBlocks.
    END METHOD.
    
    METHOD PUBLIC INT64 size():
        RETURN iTotBlockSize.
    END.
    
    METHOD PUBLIC INTEGER getNumBlocks():
        RETURN iNumBlocks.
    END.
    
    METHOD PUBLIC CHARACTER getBlock(INPUT iBlockNum AS INTEGER):
        FIND ttChar WHERE ttChar.iPK EQ iBlockNum NO-ERROR.
        IF AVAILABLE ttChar THEN
            RETURN ttChar.c.
        ELSE
            RETURN ?.
    END.

END CLASS.