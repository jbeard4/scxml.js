define ["scxml/event","scxml/SCXML","scxml/set","scxml/async-for"],(Event,scxml,Set,asyncForEach) ->

	SimpleInterpreter = scxml.SimpleInterpreter

	printError = (e) ->
		console.error e.name
		console.error e.message
		console.error e.fileName
		console.error e.lineNumber

	results =
		testCount : 0
		testsPassed : []
		testsFailed : []
		testsErrored : []

	interpreter = null

	#TODO: refactor the outer loop to also be async. Right now, I believe this will only work for one test.
	runTests = (tests,setTimeout,clearTimeout,finish) ->

		testCallback = (test,nextStep,errBack,failBack) ->
			#start the while loop
			startAsyncFor test,nextStep

		testsFinishedCallback = ->
			finish results

		doCallback = (e,nextStep,errBack,failBack) ->
			sendEvent = ->
				try
					console.info "sending event",e["event"]["name"]
					interpreter.gen(new Event(e["event"]["name"]))
					nextConfiguration = interpreter.getConfiguration()
					expectedNextConfiguration = new Set(e["nextConfiguration"])

				catch err
					errBack err

				if nextConfiguration and expectedNextConfiguration
					if not expectedNextConfiguration.equals nextConfiguration
						console.error("Configuration error: expected " + expectedNextConfiguration + ", received " + nextConfiguration)

						failBack()
					else
						nextStep()

			if(e.after)
				console.info("e.after " + e.after)
				setTimeout(sendEvent,e.after)
			else
				sendEvent()

		startAsyncFor = (test,doNextTest) ->

			testSuccessFullyFinished = ->
				console.info "test",test["name"],"...passes"
				results.testsPassed.push test["name"]
				doNextTest()

			testFailBack = ->
				console.info "test",test["name"],"...failed"
				results.testsFailed.push test["name"]
				doNextTest()

			testErrBack = (err) ->
				console.info "test",test["name"],"...errored"
				results.testsErrored.push test["name"]
				printError err
				doNextTest()

			console.info("running test",test.name)

			results.testCount++

			try
				console.log "running test for",test.name
				interpreter = new SimpleInterpreter test.model,setTimeout,clearTimeout

				events = test.events.slice()

				console.info "starting interpreter"

				interpreter.start()
				initialConfiguration = interpreter.getConfiguration()

				console.debug "initial configuration",initialConfiguration

				expectedInitialConfiguration = new Set(test["initialConfiguration"])

				console.debug "expected configuration",expectedInitialConfiguration

			catch err
				testErrBack err

			if expectedInitialConfiguration and initialConfiguration
				if not expectedInitialConfiguration.equals(initialConfiguration)
					console.error("Configuration error: expected " + expectedInitialConfiguration + ", received " + initialConfiguration)
					testFailBack()
				else
					asyncForEach events,doCallback,testSuccessFullyFinished,testErrBack,testFailBack

		asyncForEach tests,testCallback,testsFinishedCallback,(->),(->)
