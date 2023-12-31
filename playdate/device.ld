PHDRS {
    rwx PT_LOAD FLAGS(7);
}

SECTIONS {
    .text : {
        . = .;
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    } :rwx
    .data : {
        . = .;
        *(.data)
        *(.data.*)
    } :rwx
    .bss : {
        . = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } :rwx

    /DISCARD/ : {
        *(.ARM.exidx)
    }
}
