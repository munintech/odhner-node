root = exports ? window

class Odhner
  constructor: (@input, @base = 0) ->
    @sanetizedInput = @sanetizeInput @input
    @errors = [] # Array of error messages
    @resultValue = null
      
  isValid: =>
    @isValidInput() # for now, the input determines whether we are ready to go
      
  result: =>
    return @resultValue if @resultValue? # Return the value if it has already been calculated
    if @isValidInput()
      @resultValue = @calculateValidInput() if not @resultValue?
      if isFinite(@resultValue) then @resultValue else 0 # check if calculation makes sense
    else
      throw new Error @errorsInInput() # Throw an exception for the programmer

  sanetizeInput: (input) =>
    sanetizedInput = input
    sanetizedInput = sanetizedInput.toString().replace(/\s/g, "") # remove white spaces (spaces, tabs, and line breaks)
    sanetizedInput

  isValidInput: =>
    @resetErrors() # to avoid duplicated error messages
    regexContainsInvalidCharacters = /// # The string contains invalid characters (is there a character which is neither of the following?) -
      [ # - if the individual character is -
        ^\d # not a digit (0-9) and
        ^\+ # not a plus (+) and
        ^\- # not a minus (-) and
        ^\* # not a star (*) and
        ^\/ # not a slash (/) and
        ^\. # not a dot (.) and
        ^\, # not a comma (,) and
        ^\( # not an open bracket "(" and
        ^\) # not a close bracket ")"
      ]
    /// 
    regexContainsAdjacentOperands = /// # The string contains invalid use of operands -
      [ # - if the individual character is -
        \+ # a plus (+) or
        \- # a minus (-) or
        \* # a star (*) or
        \/ # a slash (/)
      ]
      {2} # two characters in a row (=adjacent to each other)
    ///
    regexContainsOperandAtEnd = /// # The string contains invalid use of an operand at the end -
      [ #   - if the character is -
        \+ #  a plus (+) or
        \- #  a minus (-) or
        \* #  a star (*) or
        \/ #  a slash (/)
      ]
      $ #   - at the end of the string
    ///
    isValid = true
    if regexContainsInvalidCharacters.test @sanetizedInput # Use of invalid characters
      isValid = false
      @addError "Invalid input. The input includes some odd characters. It can only include digits (0-9), plus (+), minus (-), star (*), slash (/) and brackets \"(\" or \").\""
    if regexContainsAdjacentOperands.test @sanetizedInput # Use of adjacent operands
      isValid = false
      @addError 'Invalid input. The input includes two adjacent operands (+, -, * or /) which the calculator do not know how to handle.'
    if regexContainsOperandAtEnd.test @sanetizedInput # Use of operand at the end
      isValid = false
      @addError 'Invalid input. The input ends with an operand (+, -, * or /). The calculator does not know how to handle this. Would you?'
    try
      @resultValue = @calculateValidInput()
    catch error
      @addError "You did something crazy that Cal does not know how to handle. '#{error.toString()},' he says."
      isValid = false
    finally
      return isValid
      
  errorsInInput: =>
    @errors
    
  addError: (errorMessage) =>
    @errors.push errorMessage
    #console.log 'Error recorded for ' + @input + ' (' + errorMessage + ')'
    
  resetErrors: =>
    @errors = []

  calculateValidInput: =>
    evalString = @inputWithInferedSeparators(@sanetizedInput)
    if /^[\+\-\*\/]/.test evalString # check for + - * / characters in the first position TODO: Make more strutable
      evalString = @base + evalString
    eval evalString
    
  # ------------- FUNCTIONS FOR SANITIZING INPUT -------------------- >>>
  inputWithInferedSeparators: (input) =>
    originalOperandsAndNumbers = []
    operandsAndSanetizedNumbers = []
    originalOperandsAndNumbers = @operandsAndNumbersInString input
    for element in originalOperandsAndNumbers
      if @isNumber element
        number = element
        sanetizedNumber = @numberWithOneOrNoDelimiter number
        if (isCriticalNumber = @isCriticalNumber(sanetizedNumber))
          sanetizedNumber = @mostProbableNumber(sanetizedNumber)
        operandsAndSanetizedNumbers.push sanetizedNumber
        #console.log "'#{number}' #{@partBeforeDecimal(number)}+#{@partFromDecimal(number)} result: #{sanetizedNumber} (is critical? #{isCriticalNumber} / same delimiter? #{@sameDelimiterUsedMultpleTimes(number)})"
      else
        operandsAndSanetizedNumbers.push element
    sanetizedInput = @compileStringFromArray operandsAndSanetizedNumbers
    #console.log "FINAL sanitized string: #{input} -> #{sanetizedInput}"
    sanetizedInput
    
  operandsAndNumbersInString: (input) =>
    elements = []
    regexNumberOrOperand = ///
      [\d\.\,]+ # one or more digits, dots or commas
      | # or
      [\+\-\*\/\(\)]+ # one or more operands (or brackets)
      ///g
    result = regexNumberOrOperand.exec input # start loop
    while result?
      #alert result
      elements.push result
      result = regexNumberOrOperand.exec input
    elements
    
  isNumber: (element) =>
    regexNumber = /[\d\.\,]+/ # A block consisting of one or more digits, dots (.) or commas (,)
    regexNumber.test element
    
  numberWithOneOrNoDelimiter: (input) =>
    if @sameDelimiterUsedMultpleTimes(input)
      @removeByRegex(input,/[\.\,]/g)
    else
      @partBeforeDecimal(input) + @partFromDecimal(input)
      
  mostProbableNumber: (number) =>
    if @isProbableNumber(number)
      number
    else
      numberWitoutDecimal = @numberWitoutDecimal(number)
      if @isProbableNumber(numberWitoutDecimal)
        return numberWitoutDecimal
      else
        number
    
  sameDelimiterUsedMultpleTimes: (input) =>
    if (/\..*\./g.test(input) and not /\,/.test(input)) # if one dot is followed by another without any commas involved
      true
    else if (/\,.*\,/g.test(input) and not /\./g.test(input)) # if or one comma by another without any dots
      true
    else
      false 
    
  partFromDecimal: (input) =>
    regexFirstDecimaFromRight = /[\.\,]\d*$/ # ASK: Should be global variable?
    part = regexFirstDecimaFromRight.exec input
    sanetizedPart = part.toString().replace(/[\,]/g,'.') if part? # dots are used as decimals by standard
    if sanetizedPart? then sanetizedPart else ''
        
  partBeforeDecimal: (input) =>
    regexFirstDecimaFromRight = /[\.\,]\d*$/ # ASK: Should be global variable?
    part = @removeByRegex(input,regexFirstDecimaFromRight)
    sanetizedPart = @removeByRegex(part,/[\,\.]/g) # remove all potential decimals (dots or commas)
    if sanetizedPart? then sanetizedPart else ''
    
  removeByRegex: (input, regex) =>
    input.toString().replace(regex,'') if input?
    
  isCriticalNumber: (input) =>
    regexCriticalNumber = ///
      \d+ # one or more digits
      [\.\,] # and a dot (.) or comma (,)
      \d{3} # and 3 digits
      ///
    regexCriticalNumber.test input
    
  numberWitoutDecimal: (input) =>
    input.toString().replace(/[\,\.]/g,'')
    
  isProbableNumber: (number) => # A subjective estimate of whether the number is within a reasonable interval
    bottomBoarder = 2 # equalling and interval between 2 and 2000 in the used currency ASK: Global variable to be set when the Odhner is setup on site?
    topBoarder = bottomBoarder * 1000
    number >= bottomBoarder and number < (topBoarder)
    
  compileStringFromArray: (array) =>
    string = ""
    for element in array
      string += element
    string

  # <<< --------- FUNCTIONS FOR SANITIZING INPUT ------------------------
  
  
  formattedResult: (decimalPlaces) =>
    @format @result(@input), decimalPlaces

  format: (number,decimalPlaces) =>
    @addDelimiters @roundNumber(number,decimalPlaces)
    
  roundNumber: (number,decimalPlaces = 2) =>
    number.toFixed(decimalPlaces)  
    
  addDelimiters: (number) =>
    regexSplitByThirdDigit = /// # Finds each set of three zeros in a row until a dot or end of string is reached
      (?= # zero-width positive lookahead ("Matches only the position. It does not consume any characters or expand the match." /regular-expressions.info)
        (?: # do not create a backreference so that the content can be used later in regex or e.g. replacement
          \d{3} # three digits
        )
        + # one or more
        (?: # do not create a backreference so that the content can be used later in regex or e.g. replacement
          \. # dot
          | # or
        $) # end of string
      )
      ///g
    if /^\-/.test number # if the first character is a minus (-), the number is negative
      positiveNumber = /[^\-]+/.exec number # extract everything which is not a minus (-)
      prefix = '-'
    else
      positiveNumber = number
      prefix = ''
    prefix + positiveNumber.toString().split(regexSplitByThirdDigit).join( "," ) # Splits the number for each set of three zeros and adds a comma (,) between them
        
  
  @split: (number, parts) -> 
    number = parseFloat(number)
    parts = parseInt(parts)
    amount = number / parts

    if isFinite(amount)
      amount
    else
      0

  @format: (input, decimalPlaces) ->
    odhner = new Odhner input
    if odhner.isValid()
      odhner.formattedResult decimalPlaces
    else
      input


# ==================================
# jQuery plugin for Odhner.
# ==================================
#
# Will automatically be available if jQuery is included.
#
# Usage: $('#my-input-field').odhner([options])
#
# Hitting enter in the input field, will replace the input field's value with the calculated result.
#
# As default, it will alert errors.
# This can be overriden by parsing an onError function to the initializer.
# Fx to log errors in the console instead:
# $('#my-input-field').odhner(onError: (errors) -> console.log errors)

if jQuery?
  (($) ->
    $.fn.odhner = (options) ->
      settings = $.extend(
        onError: (errors) -> alert errors
      , options)

      @each -> 
        $(this).keydown (e) ->
          keyCode = e.keyCode || e.which
          return unless keyCode == 13 # Enter
          e.preventDefault()
          input = $(this).val()
          calculator = new Odhner input
          if calculator.isValid()
            $(this).val calculator.result()
          else
            settings.onError calculator.errorsInInput()
  )(jQuery)

# Make odhner available in the global scope.
root.Odhner = Odhner
