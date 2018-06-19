//
//  IntentHandler.swift
//  ToDoIntents
//
//  Created by Shengbo Lou on 6/18/18.
//  Copyright © 2018 Shengbo Lou. All rights reserved.
//

import Intents
// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

class IntentHandler: INExtension, INCreateNoteIntentHandling{
    func handle(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Void) {
        guard let content = intent.content else{
            completion(INCreateNoteIntentResponse(code: INCreateNoteIntentResponseCode.failure, userActivity: nil))
            return
        }

        let managedContext = CoreDataStack.resultsController.managedObjectContext
        let todo = Todo(context:managedContext)
        todo.title = (intent.content as? INTextNoteContent)?.text
        todo.date = Date()

        do{
            try managedContext.save()
        }catch{
            print("Error saving the item")
        }
        
        let response = INCreateNoteIntentResponse(code: INCreateNoteIntentResponseCode.success, userActivity: nil)
        response.createdNote = INNote(title: intent.title ?? INSpeakableString(spokenPhrase: "Task"), contents: [content], groupName: nil, createdDateComponents: nil, modifiedDateComponents: nil, identifier: nil)
        completion(response)
        
    }
    
    
}

