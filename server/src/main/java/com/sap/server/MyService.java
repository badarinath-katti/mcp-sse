package com.sap.server;

import org.springframework.ai.tool.annotation.Tool;
//import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Service;

@Service
public class MyService {

	@Tool(description = "Check how the stocks are doing for a given company")
	public String howsStocks(  String company ) {
		if( "IBM".equals(company) ) {
			return "stocks are up 10%";
		} else if( "MSFT".equals(company) ) {
			return "MSFT stocks are up 20%";
		} else if( "SAP".equals(company) ) {
			return "SAP stocks are up 50%";
		} else {
			return "Unknown company: " + company;
		}
	}

	@Tool(description = "Get the current stock price for a given company")
	public String getStockPrice(  String company ) {
		if( "IBM".equals(company) ) {
			return "135.67 USD";
		} else if( "MSFT".equals(company) ) {
			return "256.78 USD";
		} else if( "SAP".equals(company) ) {
			return "123.45 EUR";
		} else {
			return "Unknown company: " + company;
		}
	}
}
