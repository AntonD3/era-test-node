object "EcAdd" {
	code { }
	object "EcAdd_deployed" {
		code {
            ////////////////////////////////////////////////////////////////
            //                      CONSTANTS
            ////////////////////////////////////////////////////////////////

            function ZERO() -> zero {
                zero := 0x0
            }

            function ONE() -> one {
                one := 0x1
            }

            function TWO() -> two {
                two := 0x2
            }

            function THREE() -> three {
                three := 0x3
            }

            function MONTGOMERY_ONE() -> m_one {
                m_one := 6350874878119819312338956282401532409788428879151445726012394534686998597021
            }

            function MONTGOMERY_TWO() -> m_two {
                m_two := 12701749756239638624677912564803064819576857758302891452024789069373997194042
            }

            function MONTGOMERY_THREE() -> m_three {
                m_three := 19052624634359457937016868847204597229365286637454337178037183604060995791063
            }

            // Group order of alt_bn128, see https://eips.ethereum.org/EIPS/eip-196
            function ALT_BN128_GROUP_ORDER() -> ret {
                ret := 21888242871839275222246405745257275088696311157297823662689037894645226208583
            }

            function R2_MOD_ALT_BN128_GROUP_ORDER() -> ret {
                ret := 3096616502983703923843567936837374451735540968419076528771170197431451843209
            }

            function R3_MOD_ALT_BN128_GROUP_ORDER() -> ret {
                ret := 14921786541159648185948152738563080959093619838510245177710943249661917737183
            }

            function N_PRIME() -> ret {
                ret := 111032442853175714102588374283752698368366046808579839647964533820976443843465
            }

            // ////////////////////////////////////////////////////////////////
            //                      HELPER FUNCTIONS
            // ////////////////////////////////////////////////////////////////

            // @dev Packs precompile parameters into one word.
            // Note: functions expect to work with 32/64 bits unsigned integers.
            // Caller should ensure the type matching before!
            function unsafePackPrecompileParams(
                uint32_inputOffsetInWords,
                uint32_inputLengthInWords,
                uint32_outputOffsetInWords,
                uint32_outputLengthInWords,
                uint64_perPrecompileInterpreted
            ) -> rawParams {
                rawParams := uint32_inputOffsetInWords
                rawParams := or(rawParams, shl(32, uint32_inputLengthInWords))
                rawParams := or(rawParams, shl(64, uint32_outputOffsetInWords))
                rawParams := or(rawParams, shl(96, uint32_outputLengthInWords))
                rawParams := or(rawParams, shl(192, uint64_perPrecompileInterpreted))
            }

            /// @dev Executes the `precompileCall` opcode.
            function precompileCall(precompileParams, gasToBurn) -> ret {
                // Compiler simulation for calling `precompileCall` opcode
                ret := verbatim_2i_1o("precompile", precompileParams, gasToBurn)
            }

            // Returns 1 if (x, y) is in the curve, 0 otherwise
            function pointIsInCurve(
                uint256_x,
                uint256_y,
            ) -> ret {
                let y_squared := mulmod(uint256_y, uint256_y, ALT_BN128_GROUP_ORDER())
                let x_squared := mulmod(uint256_x, uint256_x, ALT_BN128_GROUP_ORDER())
                let x_qubed := mulmod(x_squared, uint256_x, ALT_BN128_GROUP_ORDER())
                let x_qubed_plus_three := addmod(x_qubed, 3, ALT_BN128_GROUP_ORDER())

                ret := eq(y_squared, x_qubed_plus_three)
            }

            function submod(
                uint256_minuend,
                uint256_subtrahend,
                uint256_modulus,
            ) -> difference {
                difference := addmod(uint256_minuend, sub(uint256_modulus, uint256_subtrahend), uint256_modulus)
            }

            function isInfinity(
                uint256_x,
                uint256_y,
            ) -> ret {
                ret := and(eq(uint256_x, ZERO()), eq(uint256_y, ZERO()))
            }

            function isOnGroupOrder(num) -> ret {
                ret := iszero(gt(num, sub(ALT_BN128_GROUP_ORDER(), ONE())))
            }

            function burnGas() {
                let precompileParams := unsafePackPrecompileParams(
                        0, // input offset in words
                        4, // input length in words (x1, y1, x2, y2)
                        0, // output offset in words
                        2, // output length in words (x3, y3)
                        0  // No special meaning
                )
                let gasToPay := gas()

                // Precompiles that do not have a circuit counterpart
                // will burn the provided gas by calling this function.
                precompileCall(precompileParams, gasToPay)
            }

            function binaryExtendedEuclideanAlgorithm(base) -> inv {
                // Precomputation of 1 << 255
                let mask := 57896044618658097711785492504343953926634992332820282019728792003956564819968
                let modulus := ALT_BN128_GROUP_ORDER()
                // modulus >> 255 == 0 -> modulus & 1 << 255 == 0
                let modulusHasSpareBits := iszero(and(modulus, mask))

                let u := base
                let v := modulus
                // Avoids unnecessary reduction step.
                let b := R2_MOD_ALT_BN128_GROUP_ORDER()
                let c := ZERO()

                for {} and(iszero(eq(u, ONE())), iszero(eq(v, ONE()))) {} {
                    for {} iszero(and(u, ONE())) {} {
                        u := shr(1, u)
                        let current_b := b
                        let current_b_is_odd := and(current_b, ONE())
                        if iszero(current_b_is_odd) {
                            b := shr(1, b)
                        }
                        if current_b_is_odd {
                            let new_b := add(b, modulus)
                            let carry := or(lt(new_b, b), lt(new_b, modulus))
                            b := shr(1, new_b)

                            if and(iszero(modulusHasSpareBits), carry) {
                                b := or(b, mask)
                            }
                        }
                    }

                    for {} iszero(and(v, ONE())) {} {
                        v := shr(1, v)
                        let current_c := c
                        let current_c_is_odd := and(current_c, ONE())
                        if iszero(current_c_is_odd) {
                            c := shr(1, c)
                        }
                        if current_c_is_odd {
                            let new_c := add(c, modulus)
                            let carry := or(lt(new_c, c), lt(new_c, modulus))
                            c := shr(1, new_c)

                            if and(iszero(modulusHasSpareBits), carry) {
                                c := or(c, mask)
                            }
                        }
                    }

                    switch gt(v, u)
                    case 0 {
                        u := sub(u, v)
                        if lt(b, c) {
                            b := add(b, modulus)
                        }
                        b := sub(b, c)
                    }
                    case 1 {
                        v := sub(v, u)
                        if lt(c, b) {
                            c := add(c, modulus)
                        }
                        c := sub(c, b)
                    }
                }

                switch eq(u, ONE())
                case 0 {
                    inv := c
                }
                case 1 {
                    inv := b
                }
            }

            function overflowingAdd(augend, addend) -> sum, overflowed {
                sum := add(augend, addend)
                overflowed := or(lt(sum, augend), lt(sum, addend))
            }

            function getHighestHalfOfMultiplication(multiplicand, multiplier) -> ret {
                ret := verbatim_2i_1o("mul_high", multiplicand, multiplier)
            }

            // https://en.wikipedia.org/wiki/Montgomery_modular_multiplication//The_REDC_algorithm
            function REDC(lowest_half_of_T, higher_half_of_T) -> S {
                let q := mul(lowest_half_of_T, N_PRIME())
                let a_high := add(higher_half_of_T, getHighestHalfOfMultiplication(q, ALT_BN128_GROUP_ORDER()))
                let a_low, overflowed := overflowingAdd(lowest_half_of_T, mul(q, ALT_BN128_GROUP_ORDER()))
                if overflowed {
                        a_high := add(a_high, ONE())
                }
                S := a_high
                if iszero(lt(a_high, ALT_BN128_GROUP_ORDER())) {
                        S := sub(a_high, ALT_BN128_GROUP_ORDER())
                }
            }

            // Transforming into the Montgomery form -> REDC((a mod N)(R2 mod N))
            function intoMontgomeryForm(a) -> ret {
                let higher_half_of_a := getHighestHalfOfMultiplication(mod(a, ALT_BN128_GROUP_ORDER()), R2_MOD_ALT_BN128_GROUP_ORDER())
                let lowest_half_of_a := mul(mod(a, ALT_BN128_GROUP_ORDER()), R2_MOD_ALT_BN128_GROUP_ORDER())
                ret := REDC(lowest_half_of_a, higher_half_of_a)
            }

            // Transforming out of the Montgomery form -> REDC(a * R mod N)
            function outOfMontgomeryForm(m) -> ret {
                let higher_half_of_m := ZERO()
                let lowest_half_of_m := m
                ret := REDC(lowest_half_of_m, higher_half_of_m)
            }

            // Multipling field elements in Montgomery form -> REDC((a * R mod N)(b * R mod N))
            function montgomeryMul(multiplicand, multiplier) -> ret {
                let higher_half_of_product := getHighestHalfOfMultiplication(multiplicand, multiplier)
                let lowest_half_of_product := mul(multiplicand, multiplier)
                ret := REDC(lowest_half_of_product, higher_half_of_product)
            }

            function montgomeryModExp(base, exponent) -> pow {
                pow := MONTGOMERY_ONE()
                let aux_exponent := exponent
                for { } gt(aux_exponent, ZERO()) { } {
                        if mod(aux_exponent, 2) {
                            pow := montgomeryMul(pow, base)
                        }
                        aux_exponent := shr(1, aux_exponent)
                        base := montgomeryMul(base, base)
                }
            }

            function montgomeryModularInverse(a) -> invmod {
                invmod := binaryExtendedEuclideanAlgorithm(a)
            }

            function montgomeryDiv(dividend, divisor) -> quotient {
                quotient := montgomeryMul(dividend, montgomeryModularInverse(divisor))
            }

            ////////////////////////////////////////////////////////////////
            //                      FALLBACK
            ////////////////////////////////////////////////////////////////

            // Retrieve the coordinates from the calldata
            let x1 := calldataload(0)
            let y1 := calldataload(32)
            let x2 := calldataload(64)
            let y2 := calldataload(96)


            if and(isInfinity(x1, y1), isInfinity(x2, y2)) {
                // Infinity + Infinity = Infinity
                mstore(0, ZERO())
                mstore(32, ZERO())
                return(0, 64)
            }
            if and(isInfinity(x1, y1), iszero(isInfinity(x2, y2))) {
                // Infinity + P = P

                // Ensure that the coordinates are between 0 and the group order.
                if or(iszero(isOnGroupOrder(x2)), iszero(isOnGroupOrder(y2))) {
                        burnGas()
                        revert(0, 0)
                }

                // Ensure that the point is in the curve (Y^2 = X^3 + 3).
                if iszero(pointIsInCurve(x2, y2)) {
                        burnGas()
                        revert(0, 0)
                }

                mstore(0, x2)
                mstore(32, y2)
                return(0, 64)
            }
            if and(iszero(isInfinity(x1, y1)), isInfinity(x2, y2)) {
                // P + Infinity = P

                // Ensure that the coordinates are between 0 and the group order.
                if or(iszero(isOnGroupOrder(x1)), iszero(isOnGroupOrder(y1))) {
                        burnGas()
                        revert(0, 0)
                }

                // Ensure that the point is in the curve (Y^2 = X^3 + 3).
                if iszero(pointIsInCurve(x1, y1)) {
                        burnGas()
                        revert(0, 0)
                }

                mstore(0, x1)
                mstore(32, y1)
                return(0, 64)
            }

            // Ensure that the coordinates are between 0 and the group order.
            if or(iszero(isOnGroupOrder(x1)), iszero(isOnGroupOrder(y1)), iszero(isOnGroupOrder(x2)), iszero(isOnGroupOrder(y2))) {
                burnGas()
                revert(0, 0)
            }

            // Ensure that the points are in the curve (Y^2 = X^3 + 3).
            if or(iszero(pointIsInCurve(x1, y1)), iszero(pointIsInCurve(x2, y2))) {
                burnGas()
                revert(0, 0)
            }

            // There's no need for transforming into Montgomery form
            // for this case.
            if and(eq(x1, x2), eq(submod(0, y1, ALT_BN128_GROUP_ORDER()), y2)) {
                // P + (-P) = Infinity

                mstore(0, ZERO())
                mstore(32, ZERO())
                return(0, 64)
            }
            // There's no need for transforming into Montgomery form
            // for this case.
            if and(eq(x1, x2), and(iszero(eq(y1, y2)), iszero(eq(y1, submod(0, y2, ALT_BN128_GROUP_ORDER()))))) {
                burnGas()
                revert(0, 0)
            }

            if and(eq(x1, x2), eq(y1, y2)) {
                // P + P = 2P

                let x := intoMontgomeryForm(x1)
                let y := intoMontgomeryForm(y1)

                // (3 * x1^2 + a) / (2 * y1)
                let slope := montgomeryDiv(montgomeryMul(MONTGOMERY_THREE(), montgomeryMul(x, x)), addmod(y, y, ALT_BN128_GROUP_ORDER()))
                // x3 = slope^2 - 2 * x1
                let x3 := submod(montgomeryMul(slope, slope), addmod(x, x, ALT_BN128_GROUP_ORDER()), ALT_BN128_GROUP_ORDER())
                // y3 = slope * (x1 - x3) - y1
                let y3 := submod(montgomeryMul(slope, submod(x, x3, ALT_BN128_GROUP_ORDER())), y, ALT_BN128_GROUP_ORDER())

                x3 := outOfMontgomeryForm(x3)
                y3 := outOfMontgomeryForm(y3)

                mstore(0, x3)
                mstore(32, y3)
                return(0, 64)
            }

            // P1 + P2 = P3

            x1 := intoMontgomeryForm(x1)
            y1 := intoMontgomeryForm(y1)
            x2 := intoMontgomeryForm(x2)
            y2 := intoMontgomeryForm(y2)

            // (y2 - y1) / (x2 - x1)
            let slope := montgomeryDiv(submod(y2, y1, ALT_BN128_GROUP_ORDER()), submod(x2, x1, ALT_BN128_GROUP_ORDER()))
            // x3 = slope^2 - x1 - x2
            let x3 := submod(montgomeryMul(slope, slope), addmod(x1, x2, ALT_BN128_GROUP_ORDER()), ALT_BN128_GROUP_ORDER())
            // y3 = slope * (x1 - x3) - y1
            let y3 := submod(montgomeryMul(slope, submod(x1, x3, ALT_BN128_GROUP_ORDER())), y1, ALT_BN128_GROUP_ORDER())

            x3 := outOfMontgomeryForm(x3)
            y3 := outOfMontgomeryForm(y3)

            mstore(0, x3)
            mstore(32, y3)
            return(0, 64)
		}
	}
}
