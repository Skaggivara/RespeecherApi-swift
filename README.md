# Respeecher API

Documentation for the API: https://gateway.respeecher.com/api/docs

## Overview

The Respeecher API is constructed around 3 main concepts: Project, Phrase and Recording.

Project is just a high level organisation. Phrase is a piece of text or audio to be transformed. Recording is an original recording or a converted one either from audio or from text through TTS.

You create a Phrase within a Project and then upload a recording or provide a text for which you then create an order to transform it into a new recording using a speech model. The resulting recording will be listed under the same Phrase. 

## Usage

Create instance of RespeechApi, authentication cookie is saved in NSUserdefaults and loaded on init. So when api instance is created first check if already authenticated.

Check authentication:

    api.isAuthenticated

Login if needed:

    api.login(username: username, password: password) { authenticated in
        print("authenticated: \(authenticated)")
    }

Listen to authStatus changes:

    api.delegate = self

    ...

    func authStatusChanged(_ sender: RespeechApi, authenticated: Bool) {
        print("authenticated: \(authenticated)")
    }

Fetch projects:

    api.fetchProjects { results in
        print(results)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to fetch")
        }
    }

Fetch phrases for a given project:

    api.fetchPhrases(projectId: projectId) { results in
        print(results)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to fetch phrases")
        }
    }

Fetch recordings for a given phrase:

    api.fetchRecordings(phraseId: phraseId) { results in
        print(results)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to fetch recordings")
        }
    }

Fetch models:

    api.fetchModels { results in
        print(results)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to fetch Models")
        }
    }

Create phrase:

    api.createPhrase(projectId: projectId, phrase: phraseName) { phrase in
        print(phrase)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to create Phrase")
        }
    }

Create recording:

You can create a recording belonging to a phrase. A recording is a sound file in the one of the following file formats: ('wav', 'ogg', 'mp3', 'flac')

PHRASE_ID = phrase id
DATA = sound file data (Data) instance of sound file
FILENAME = name of file
MIMETYPE = sound file mime type, example: "audio/wav"

    api.createRecording(phraseId: PHRASE_ID, recording: DATA, fileName: FILENAME, mimeType: MIMETYPE) { recording in
        guard let originalId = recording?.originalId else {
            print("error")
            return
        }
        print("recording created")
    } onProgress: { progress in
        print("upload progress: \(progress)")
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("upload failed")
        }
    }

Create recording order:

You reference a recording's originalId to start a conversion using a specified model.

modelParams = list of parameters for model, see RespeecherModel's defaultParams()

    api.createOrder(originalId: originalId, modelId: modelId, modelName: modelName, modelParams: modelParams) { recording in
        print(recording)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to created order")
        }
    }

Fetch TTS voices:

Before creating a TTS recording you need a TTS voice to use.

    api.fetchTTSVoices { results in
        print(results)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to fetch Voices")
        }
    }

Create TTS file:

    api.createTTS(phraseId: phraseId, voice: voiceName, text: text) { recording in
        print(recording)
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to initiate TTS")
        }
    }

Download recording to Documentsdir:

    api.downloadRecording(recording) { result in
        print(result)
    } onProgress: { progress in
        print("download progress: \(progress)")
    } onFailure: { error in
        if error == .authFailed {
            print("auth failed")
        } else {
            print("failed to download recording")
        }
    }
