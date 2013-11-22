## Standard Macros ##

~~~~~{.C}
/*
 * BitMacros.h
 */

#ifndef BITMACROS_H_
#define BITMACROS_H_

	// Some macros to speed bit twiddling
	#define BITVALUE(var) (1 << (var))
	#define BITON(var,bit) var |= (1 << bit)
	#define BITOFF(var,bit) var &= ~(1 << bit)
	#define BITTOG(var,bit) var ^= (1 << bit)

	// MASK(3,4) = 0x78
	#define MASK(start,len) (~(~0 << (len)) << start)
	#define INVMASK(start,len) (~MASK(start,len))

	// OR with things to set all 1s
	#define ORMASK(start,len,val) (MASK(start,len) & ((val) << (start)))

	// AND with things to set all 0s
	#define ANDMASK(start,len,val) (INVMASK(start,len) | ((val) << (start)))

	// Shift a set of bits over and mask it to that length
	//  same as or mask with slightly different ordering
	#define SHIFTMASK(val,start,len) ORMASK(start,len,val)

	// SETBITS does two write passes, first pushing all
	//  the 1s from val, and then all the 0s. This should
	//  keep from re-setting any bits that are already or
	//  writing 1 to any unset bits.
	#define SETBITS(var,start,len,val)\
		do { \
			var |= ORMASK(start,len,val); \
			var &= ANDMASK(start,len,val); \
		} while (0)

	#define GETBIT(var,start) (((var) & (1 << (start))) >> (start))
	#define GETBITS(var,start,len) (((var) & MASK(start,len)) >> start)

	#define LOWBYTE(var) ((char) ((var) & 0xFF))
	#define HIGHBYTE(var) ((char) (((ushort_t)(var)) >> 8) & 0xFF)

#endif /* BITMACROS_H_ */
~~~~~
