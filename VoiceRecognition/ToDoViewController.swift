//
//  ToDoViewController.swift
//  VoiceRecognition
//
//  Created by Shengbo Lou on 6/11/18.
//  Copyright © 2018 Shengbo Lou. All rights reserved.
//

import UIKit
import Speech
import CoreData
import CoreSpotlight
import Intents

class ToDoViewController: UIViewController, SFSpeechRecognizerDelegate{
    
    //outlets
    @IBOutlet var resultText: UITextView!
    @IBOutlet var recordBtn: UIButton!
    @IBOutlet var addBtn: UIButton!
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier:"en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var managedContext:  NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        userActivity = NSUserActivity.viewMenuActivity
        self.recordBtn.isEnabled = false
        var statusOK = false
        
        speechRecognizer?.delegate = self
        
        //get user authorization
        SFSpeechRecognizer.requestAuthorization{(status) in
            switch status{
            case .authorized:
                statusOK = true
            case .denied:
                statusOK = false
                print("Access is denied")
                self.sendAlert(alertTitle: "Fatal", alertMessage: "User denied the access.")
            case .notDetermined:
                statusOK = false
                print("Authorization is not determined")
                self.sendAlert(alertTitle: "Fatal", alertMessage: "Authorization is not determined.")
            case .restricted:
                statusOK = false
                print("Access is restricted")
                self.sendAlert(alertTitle: "Fatal", alertMessage: "Access is restricted.")
            }
            
            //push task to main thread
            DispatchQueue.main.async {
                self.recordBtn.isEnabled = statusOK
            }

        }
        
        //add Done button to the keyboard
        //TODO: find a better way to deal with keyboard
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(self.doneClicked))
        toolBar.setItems([doneButton], animated: true)
        self.resultText.inputAccessoryView = toolBar
    }
    
    @objc func doneClicked() {
        view.endEditing(true)
    }
    
    //record button pressed
    @IBAction func recordPressed(_ sender: UIButton) {
        if self.audioEngine.isRunning{ //if running, reset
            self.audioEngine.stop()
            recognitionRequest?.endAudio()
            self.recordBtn.isEnabled = false
            self.recordBtn.setTitle("Start Recording", for: .normal)
            self.recordBtn.setTitleColor(.white, for: .normal)
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                self.recordBtn.backgroundColor = UIColor(red:0.57, green:0.57, blue:0.60, alpha:1.0)
            }
        }
        else{ // if not running, start recording
            resultText.text.removeAll()
            resultText.textColor = .black
            self.addBtn.isHidden = false
            startRecording()
            self.recordBtn.setTitle("Stop Recording", for: .normal)
            self.recordBtn.setTitleColor(.red, for: .normal)
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                self.recordBtn.backgroundColor = .white
            }
        }
    }
    
    //send alert to user
    func sendAlert(alertTitle: String, alertMessage: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            print("Alert presented")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    //add button pressed
    @IBAction func addPressed(_ sender: UIButton) {
        guard let result = self.resultText.text, !result.isEmpty else{
            print("Cannot be empty!!")
            sendAlert(alertTitle: "Alert", alertMessage: "Content can't be empty!")
            return
        }
        
        let todo = Todo(context: managedContext)
        
        todo.title = result
        todo.date = Date()
        
        do{
            try managedContext.save()
        }catch{
            print("Error saving the item")
        }
        
        let createNoteIntent = INCreateNoteIntent(title: INSpeakableString(spokenPhrase: "Task"), content: INTextNoteContent(text: result), groupName: nil)
        createNoteIntent.suggestedInvocationPhrase="Create a task"
        let interaction = INInteraction(intent: createNoteIntent, response: nil)
        interaction.donate { (error) in
            if error != nil {
                if let error = error as NSError? {
                    print("Interaction donation failed: \(error)")
                }
            } else {
                print("Successfully donated interaction")
            }
        }
        
        dismiss(animated: true)
        
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    //check if speech recognizer is available
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available{
            self.recordBtn.isEnabled = true
        }
        else{
            self.recordBtn.isEnabled = false
        }
    }
    
    //fucntion that handles recording
    func startRecording() {
        //if task is not nil, reset
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do{
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        }catch{
            print("Error while setting audio properties")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else{
            fatalError("Unable to create request object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler:{
            (result, error) in
            var isFinal = false
            
            if result != nil{
                self.resultText.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal{
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionTask = nil
                self.recognitionRequest = nil
                self.recordBtn.isEnabled = true
            }
        })
        
        //get the format and add audio input to the request object
        let format = inputNode.inputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do{
            try audioEngine.start()
        }catch{
            print("Audio engine can't start")
        }
        
    }
    

}

extension ToDoViewController: UITextViewDelegate{
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.addBtn.isHidden{
            if textView.text == "I'm listening." || textView.text == "I'm listening.." {
                textView.text.removeAll()
            }
            textView.textColor = .black
            self.addBtn.isHidden = false
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
}


extension NSUserActivity {
    
    //    public struct ActivityKeys {
    //        public static let menuItems = "menuItems"
    //        public static let segueId = "segueID"
    //    }
    //
    //    private static let searchableItemContentType = "Soup Menu"
    //
    public static let viewMenuActivityType = "com.example.app.viewDetail"
    
    public static var viewMenuActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: NSUserActivity.viewMenuActivityType)
        
        // User activites should be as rich as possible, with icons and localized strings for appropiate content attributes.
        userActivity.title = "Title"
        userActivity.isEligibleForSearch = true
        if #available(iOS 12.0, *) {
            userActivity.isEligibleForPrediction = true
        } else {
            // Fallback on earlier versions
            print("Doesn't support")
        }
        
        //        #if os(iOS)
        let attributes = CSSearchableItemAttributeSet(itemContentType: NSUserActivity.viewMenuActivityType)
        attributes.keywords = userActivity.viewMenuSearchableKeywords
        attributes.displayName = "VoiceToDo"
        let description = "Click here to set up task"
        attributes.contentDescription = description
        
        userActivity.contentAttributeSet = attributes
        //        #endif
        //
        //        let phrase = "create"
        //        userActivity.suggestedInvocationPhrase = phrase
        return userActivity
    }
    
    private var viewMenuSearchableKeywords: [String] {
        return ["Task"]
    }
}


