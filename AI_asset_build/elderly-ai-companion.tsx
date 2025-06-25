import React, { useState, useRef, useEffect } from 'react';
import { Send, Mic, MicOff, Volume2 } from 'lucide-react';

const AICompanionChat = () => {
  const [message, setMessage] = useState('');
  const [isListening, setIsListening] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  const [currentResponse, setCurrentResponse] = useState('');
  const textareaRef = useRef(null);

  // Sample responses for demonstration
  const sampleResponses = [
    "I'm here to help! What would you like to talk about today?",
    "That sounds interesting. Tell me more about that.",
    "I understand. How are you feeling about that?",
    "That's wonderful to hear! I'm glad you shared that with me.",
    "I'm always here to listen and chat whenever you need me.",
    "Would you like to talk about something else, or continue with this topic?"
  ];

  const simulateTyping = (response) => {
    setIsTyping(true);
    setCurrentResponse('');
    
    let index = 0;
    const typingInterval = setInterval(() => {
      if (index < response.length) {
        setCurrentResponse(prev => prev + response[index]);
        index++;
      } else {
        clearInterval(typingInterval);
        setIsTyping(false);
      }
    }, 30);
  };

  const handleSendMessage = () => {
    if (message.trim()) {
      // Simulate AI response
      const randomResponse = sampleResponses[Math.floor(Math.random() * sampleResponses.length)];
      setTimeout(() => {
        simulateTyping(randomResponse);
      }, 500);
      
      setMessage('');
      if (textareaRef.current) {
        textareaRef.current.style.height = 'auto';
      }
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const adjustTextareaHeight = () => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = textareaRef.current.scrollHeight + 'px';
    }
  };

  const toggleListening = () => {
    setIsListening(!isListening);
    // In a real implementation, this would start/stop speech recognition
  };

  const speakResponse = () => {
    if (currentResponse) {
      // In a real implementation, this would use text-to-speech
      console.log('Speaking:', currentResponse);
    }
  };

  useEffect(() => {
    adjustTextareaHeight();
  }, [message]);

  return (
    <div className="flex flex-col h-screen max-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 font-sans">
      {/* Header */}
      <div className="bg-white shadow-md border-b-2 border-blue-200 px-6 py-4">
        <div className="flex items-center justify-center">
          <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full flex items-center justify-center mr-4">
            <span className="text-white text-xl font-bold">AI</span>
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-800">Your AI Companion</h1>
            <p className="text-gray-600 text-lg">I'm here to chat and help</p>
          </div>
        </div>
      </div>

      {/* Chat Area */}
      <div className="flex-1 overflow-y-auto px-6 py-6">
        <div className="max-w-4xl mx-auto">
          {/* Welcome Message */}
          <div className="mb-6">
            <div className="bg-white rounded-2xl shadow-lg p-6 border-l-4 border-blue-500">
              <p className="text-xl text-gray-800 leading-relaxed">
                Hello! I'm your AI companion. I'm here to chat, listen, and help with anything you'd like to discuss. 
                What's on your mind today?
              </p>
            </div>
          </div>

          {/* Current AI Response */}
          {(currentResponse || isTyping) && (
            <div className="mb-6">
              <div className="bg-white rounded-2xl shadow-lg p-6 border-l-4 border-green-500">
                <div className="flex items-start justify-between">
                  <p className="text-xl text-gray-800 leading-relaxed flex-1">
                    {currentResponse}
                    {isTyping && <span className="animate-pulse">|</span>}
                  </p>
                  {currentResponse && !isTyping && (
                    <button
                      onClick={speakResponse}
                      className="ml-4 p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                      title="Read aloud"
                    >
                      <Volume2 size={24} />
                    </button>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Input Area */}
      <div className="bg-white border-t-2 border-blue-200 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-end space-x-4">
            {/* Voice Input Button */}
            <button
              onClick={toggleListening}
              className={`p-4 rounded-xl border-2 transition-all duration-200 ${
                isListening 
                  ? 'bg-red-500 border-red-500 text-white animate-pulse' 
                  : 'bg-white border-gray-300 text-gray-600 hover:border-blue-400 hover:bg-blue-50'
              }`}
              title={isListening ? 'Stop listening' : 'Start voice input'}
            >
              {isListening ? <MicOff size={28} /> : <Mic size={28} />}
            </button>

            {/* Text Input */}
            <div className="flex-1 relative">
              <textarea
                ref={textareaRef}
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Type your message here... (Press Enter to send)"
                className="w-full px-6 py-4 text-xl border-2 border-gray-300 rounded-xl resize-none focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all min-h-[60px] max-h-32"
                rows={1}
              />
            </div>

            {/* Send Button */}
            <button
              onClick={handleSendMessage}
              disabled={!message.trim()}
              className={`p-4 rounded-xl transition-all duration-200 ${
                message.trim()
                  ? 'bg-blue-500 text-white hover:bg-blue-600 shadow-lg'
                  : 'bg-gray-200 text-gray-400'
              }`}
              title="Send message"
            >
              <Send size={28} />
            </button>
          </div>

          {/* Helpful Tips */}
          <div className="mt-4 text-center">
            <p className="text-gray-600 text-lg">
              💡 You can type your message or use the microphone to speak
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AICompanionChat;