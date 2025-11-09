package com.sap.client;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.support.ToolCallbacks;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@CrossOrigin(origins = "http://localhost:3000")
@RestController
public class SimpleQuestion1 {

	private final ChatClient chatClient;

	public SimpleQuestion1(ChatClient.Builder chatClientBuilder, ToolCallbackProvider tools) {
		this.chatClient = chatClientBuilder.defaultToolCallbacks(tools).build();
	}

	@GetMapping("/1")
	public String f1() {
		return chatClient.prompt().user("how are you doing?").system("do not repeat the answer").call().content();
	}

	@GetMapping("/2")
	public String f2() {
		return chatClient.prompt().user("Gimme SAP company stock price?").system("Be precise.").call().content();
	}

	@PostMapping("/chat")
	public String f1(@RequestBody String userInput) {
		return chatClient.prompt().user(userInput).system("do not repeat the answer").call().content();
	}

}
