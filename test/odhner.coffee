{Odhner} = require '../src/odhner'

# Tested with mocha: http://visionmedia.github.com/mocha/
# And should.js for assertitions: https://github.com/visionmedia/should.js

describe 'Odhner', ->
  describe '#result', ->
    describe 'when a single input is parsed to the calculator', ->
      it 'can add', ->
        calculator = new Odhner('2+3')
        calculator.result().should.eql 5
      it 'can subtract', ->
        calculator = new Odhner('3-2')
        calculator.result().should.eql 1
      it 'can multiply', ->
        calculator = new Odhner('2*3')
        calculator.result().should.eql 6
      it 'can divide', ->
        calculator = new Odhner('3/2')
        calculator.result().should.eql 1.5
      it 'can use brackets', ->
        calculator = new Odhner('200 / (1 + 1)')
        calculator.result().should.eql 100
      it 'can handle negative numbers', ->
        calculator = new Odhner('(-100)')
        calculator.result().should.eql -100
      it 'can use multiple operands (Challenge 6 pass!)', ->
        calculator = new Odhner('200 - 23 + 2 * 34')
        calculator.result().should.eql 245
      it 'throws an error when letters are included in input string', ->
        calculator = new Odhner('a+3')
        calculator.result.should.throw(/odd characters/)
      it 'throws an error when illegal symbols are included in the input string', ->
        calculator = new Odhner('2&3?!')
        calculator.result.should.throw(/odd characters/)
      it 'throws an error when one legal operand is followed by another (adjacent) in the input string', ->
        calculator = new Odhner('2++5')
        calculator.result.should.throw(/adjacent operands/)
      it 'throws an error when legal operands are not followed by a digit in the input string', ->
        calculator = new Odhner('2+')
        calculator.result.should.throw(/ends with an operand/)
      it 'throws an error when brackets are not in pairs in the input string', ->
        calculator = new Odhner('2+(5+2')
        calculator.result.should.throw(/something crazy/)
      it 'throws multiple errors when multiple rules are broken in the input string', ->
        calculator = new Odhner('2&3++?!')
        calculator.result.should.throw(/odd characters/)
        calculator.result.should.throw(/adjacent operands/)
            
    describe 'when input is present and total is blank', ->
      describe 'when minus (-) is first input character', ->
        it 'can handle negative numbers', ->
          calculator = new Odhner -100
          calculator.result().should.eql -100
  
    describe 'when input and total are present', ->
      describe 'when plus (+) is the first input character', ->
        it 'adds input to total', ->
          calculator = new Odhner('+5',100)
          calculator.result().should.eql 105
      describe 'when minus (-) is first input character', ->
        it 'subtracts input from total', ->
          calculator = new Odhner('-5',100)
          calculator.result().should.eql 95
      describe 'when multiple (*) is first input character', ->
        it 'multiplies input with total', ->
          calculator = new Odhner('*5',100)
          calculator.result().should.eql 500      
      describe 'when divide (/) is first input character', ->
        it 'divides total with input', ->
          calculator = new Odhner('/5',100)
          calculator.result().should.eql 20 
        it 'returns 0 if the dividend is 0 (althought it does not follow math conventions)', ->
          calculator = new Odhner('/0',100)
          calculator.result().should.eql 0
          
    describe 'when the input contains noise', ->
      # TODO: Make sure it handles brackets () properly

      describe 'when white space is included', ->
        it 'ignores it', ->
          calculator = new Odhner('+ 50 / 2',100)
          calculator.result().should.eql 125
          
      describe 'when only dots (.) are included', ->
        it 'uses dots as decimal delimeter', ->
          calculator = new Odhner('2.554',100)
          calculator.result().should.eql 2.554
      describe 'when only dots (.) are included for a decimal number', ->
        it 'uses dots as decimal delimeter', ->
          calculator = new Odhner('0.01125')
          calculator.result().should.eql 0.01125
      describe 'when only commas (,) are included', ->
        it 'replaces the commas (,) with dots (.)', ->
          calculator = new Odhner('2,554+2,447',100)
          # calculator.result().should.eql 5.001 # ASK: Apparently '2.554+2.447' = 5.000999999994 !?
          (new Number(calculator.result().toFixed(3))).should.eql 5.001
        it 'handles millions fine', ->
          calculator = new Odhner('1,554,447+543.50',100)
          calculator.result().should.eql 1554990.5 
      describe 'when both dots and commas are included', ->
        it 'replaces the commas (,) with dots (.) for numbers wihtin 2 and 2000 ', ->
          calculator = new Odhner('2,554+2.447',100)
          (new Number(calculator.result().toFixed(3))).should.eql 5.001 # ASK: Apparently '2.554+2.447' = 5.000999999994 !?
        it 'converts each number based on an individual assessment', ->
          calculator = new Odhner('1,554+2.447',100)
          calculator.result().should.eql 1556.447
        it 'can convert all numbers in a long input string', ->
          # calculator = new Odhner('3,335+8.8/2+1.025+2.025+3.05+2,510,055.687+52',100)
          calculator = new Odhner('3,335+8.8/2+1.025+2.025+3.05+2510055.687+52',100)
          calculator.result().should.eql 2511145.497
        describe 'when several dots and/or commas are used in a number', ->
          it 'uses the dot the most to the right', ->
            calculator = new Odhner('1.101,554.447',100)
            calculator.result().should.eql 1101554.447
          it 'uses the comma the most to the right', ->
            calculator = new Odhner('1.554,447',100)
            calculator.result().should.eql 1554.447
        describe 'when the replace function does not work', ->
          it 'works anyway', -> 
            calculator = new Odhner('2,550+2,55+2,550')
            calculator.result().toFixed(2).should.eql '7.65'
          # Failing test 
          
  describe '#isValid', ->
    describe 'when input is valid', ->
      calculator = new Odhner('2 + 3')
      it 'returns true', ->
        calculator.isValid().should.be.true
    describe 'when input is invalid', ->
      calculator = new Odhner('a+3')
      it 'returns false', ->
        calculator.isValid().should.be.false
    describe 'when #isValid is called multiple times', ->
      it 'does not duplicate error messages', ->
        calculator = new Odhner('2&3?!')
        calculator.isValid()
        calculator.isValid()
        errors = calculator.errorsInInput()
        error = errors.shift()
        errors.should.not.include error
        
  describe '#errorsInInput', ->
    describe 'when input is valid', ->
      calculator = new Odhner('2 + 3')
      it 'returns empty array', ->
        calculator.errorsInInput().should.eql []
    describe 'when input is invalid', ->
      calculator = new Odhner('a+3')
      it 'returns array (with error messages)', ->
        calculator.isValid()
        calculator.errorsInInput().length.should.be.above 0
        
  describe '#format', ->
    describe 'when input is an integer > 1000', ->
      calculator = new Odhner('1500250')
      it 'returns a string with thousand delimiters', ->
        calculator.formattedResult(0).should.eql '1,500,250'
    describe 'when input is a float', ->
      it 'returns a rounded number', ->
        calculator = new Odhner('250.495')
        calculator.formattedResult(2).should.eql '250.50'
    describe 'when input is a float and > 1000', ->
      it 'returns a string with a rounded number with thousand delimiters', ->
        calculator = new Odhner('1500250.495')        
        calculator.formattedResult(2).should.eql '1,500,250.50'
    describe 'when input has operands', ->
      calculator = new Odhner('5+5')        
      it 'returns calculated result', ->
        calculator.formattedResult(0).should.eql '10'
    describe 'when no decimal places is given', ->
      calculator = new Odhner('3')  
      it 'defaults to 2 decimal places', ->
        calculator.formattedResult().should.eql '3.00'
    describe 'when a negative number is parsed', ->
      it 'it returns a formatted negative number', ->
        Odhner.format(-100).should.eql '-100.00'
    describe 'when input is invalid', ->
      calculator = new Odhner('invalid')
      it 'throws an error', ->
        calculator.formattedResult.should.throw()

  describe '.split', ->
    it 'splits a number into a given number of parts', ->
      Odhner.split(100, 2).should.eql 50

    it '4.1) returns 0 for (0, 0)', ->
      Odhner.split(0,0).should.eql 0

    it '4.2) returns 5 for (\"10\", \"2\")', ->
      Odhner.split("10","2").should.eql 5

    it '5.1) returns 0 for (\"\", \"\")', ->
      Odhner.split("","").should.eql 0

    it '5.2) returns 0 for (null, 3)', ->
      Odhner.split(null,3).should.eql 0

    it '5.3) returns 0 for (100, null)', ->
      Odhner.split(100,null).should.eql 0

    it '5.4) returns 50.25 for (100.5, 2)', ->
      Odhner.split(100.5, 2).should.eql 50.25

    it '5.5) returns 0 for (\"a12\", 2)', ->
      Odhner.split("a12",2).should.eql 0

  describe '.format', ->
    # it behaves like #format
    describe 'when input is valid', ->
      it 'formats the input', ->
        Odhner.format(1000).should.eql '1,000.00'
    describe 'when input is invalid', ->
      it 'returns the input', ->
        Odhner.format('invalid').should.eql 'invalid'
