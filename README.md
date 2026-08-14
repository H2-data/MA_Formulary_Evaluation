<div align="center">

# Medicare Advantage Formulary Evaluation

</div>

---

## **Important Notes:**

### **The Data:**

- The data for this project was obtained from a **publicly available** dataset containing medication price and beneficiary information from 2019 to 2024. It was created by the Centers for Medicare and Medicaid Services (CMS).

[Data Source](https://data.cms.gov/summary-statistics-on-use-and-payments/medicare-medicaid-spending-by-drug/medicare-part-b-spending-by-drug)

[Dataset](https://github.com/H2-data/MA_Formulary_Evaluation/blob/6924391bccd695f28df08b05fb3a94e2003b80e8/DSD_PTB_RY25_P06_V10_DYT23_HCPCS-%20250430.csv)

### **How to Run This Repository:**

- To test the code on this project, you will need access to the following resources:
  
  	- Visual Studio Code (Or any other all-inclusive coding environment.)
  	- A MySQL environment extension
  	- Power BI Desktop
  	- An OBDC Connector
  	- A Python environment extension with the following libraries installed:
 
  	 	- Pandas
		- Numpy
		- Matplotlib
		- Seaborn
  	 	- SQLalchemy
  
**Step 1.** Plug the CSV file into the python script and run it until you reach the 'Database Creation' section. 

**Step 2.** Once you get to the Database Creation section, you can put the username, password and database name into the SQL alchemy engine object. Then run the code. It should slice the cleaned data into tables and send them to the database.

**Step 3.** Run the SQL code in your SQL environment. You must do this since the code will create VIEW objects necessary for the dashboard to work.

**Step 4.** Open the Power BI pbix file.

**Step 5.** You need to have an ODBC connector since the code is MySQL. Once you've created the connection object, you can connect the database to Power BI using the Power Query. This should activate the dashboard.

### **Who is the Project's Intended Recipient?**

- This project is meant to be recieved and read by Alpha Green Insurance LLC project managers and pharmacy actuaries currently assessing the company's Medicare Advantage policies. This project will contain a complete ranking of the financial risks of every single medication, as well as an overview of medications with high liability for financial losses. These resources can be used to accurately determine how to safely alter MA policy formularies to minimize finiancial loss.
___

## **Scenario and Objective:**

Alpha Green Insurance LLC (Not a real company) wants to make changes to their formulary for select Medicare Advantage policies and supplements in 2024. They have asked me to look over the formulary data for the previous years to get a feel for the territory, and create a list of medications that can be reliably removed from a formulary. My goal is to answer the following business question:

- Which medications can be either removed from a formulary or moved into a higher medication tier to reduce losses on select policies?

I will translate this business question into data questions:

- Which medications have the **fewest beneficiaries** and **high costs**? Medications like these can safely be removed from a formulary or increased by a tier.

- Which medications have both a **high price** and a **high number of claims and beneficiaries**? It is unsafe to completely remove medications like these, but increasing their tier could reduce overall losses.

### **Data Report:**

<img width="1282" height="717" alt="Screenshot 2026-07-08 103131" src="https://github.com/user-attachments/assets/7a8ec0b6-acf3-44a8-a044-2e51f45921a3" />
<br>
___

## **Data Preprocessing:**

Aside from generic preprocessing (outliers, duplicates and missing values) I needed to alter the data structure itself. The data is in a **wide format**, meaning each item has a column for every individual year. Most of the cleaning required melting it into a long format. Below is the original data:

|Brnd\_Name|Gnrc\_Name|Tot\_Clms\_2019|Tot\_Clms\_2020|Tot\_Clms\_2021|Tot\_Clms\_2022|Tot\_Clms\_2023|
|---|---|---|---|---|---|---|
|Imogam Rabies-HT|Rabies Immune Globulin/PF|498\.0|348\.0|333\.0|373\.0|207|

The problem is the rabies vaccine has a seperate 'total claims' column for every year. This wide structure makes the data difficult to to work with. To fix this, I used the following code snippet on each individual item to melt them down, and then I rejoined them into one table.

```python
df_tot_spndng = df.melt(
    id_vars = ['HCPCS_Cd', 'HCPCS_Desc', 'Brnd_Name', 'Gnrc_Name'],  
    value_vars = ['Tot_Clms_2019','Tot_Clms_2020','Tot_Clms_2021','Tot_Clms_2022','Tot_Clms_2023'],  
    var_name = 'year',  
    value_name = 'Tot_Clms'  
)
  
df_tot_spndng['year'] = df_tot_spndng['year'].str.extract('(\d{4})').astype(int)  
df_tot_spndng.head()
```
And this is the result:

|Brnd\_Name|Gnrc\_Name|year|Tot\_Clms|
|---|---|---|---|
|Imogam Rabies-HT|Rabies Immune Globulin/PF|2019|498\.0|
|Imogam Rabies-HT|Rabies Immune Globulin/PF|2020|348\.0|
|Imogam Rabies-HT|Rabies Immune Globulin/PF|2021|333\.0|
|Imogam Rabies-HT|Rabies Immune Globulin/PF|2022|373\.0|
|Imogam Rabies-HT|Rabies Immune Globulin/PF|2023|207\.0|

Now the rabies vaccine is dupilcated once for each year, and there is a 'year' column to dilineate it. Now I can partition things by year instead of referencing a set of columns each time I need a calculation. This logic was applied to all date-identified columns in the dataset, creating a much simpler structure for use in SQL and Power BI.

To see each step of the data cleaning process, see the preprocessing section of this project, linked here:

[Preprocessing](01_medicare_medication.py)
___

## **How can I solve the problem?**

After trying a couple of different methods, I believe the most effective way to decide which medications incur the most losses is using a Weighted Composite Score since there are multiple factors that determine whether a medication is a liability. I will use 3 factors to score a medication:

- Average Spending (45%), the higher the price, the higher score
- Total Beneficiaries (inverted) (20%), the lower the number of beneficiaries, the higher the score
- Total Claims (inverted) (20%), the lower the number of claims, the higher the score
- 2022-2023 Growth (10%), the higher the growth, the higher the score
- 2021-2022 Growth (5%), the higher the growth, the higher the score

The following is a snippet of the resulting output. To keep things clean, I used Percent Rank as the standardization method, meaning each medication is ranked a number from 0 to 1 depending on it's overall score. The higher the score, the more likely the medication is a liability. I also kept the original scores for each category for later plotting.

```SQL
SELECT 
	Brnd_Name,
    year,
    ROUND(composite_score, 2) as Composite_Score
FROM final_scores
WHERE year = 2023
ORDER BY composite_score DESC;
```
<img width="552" height="381" alt="Screenshot 2026-07-08 103340" src="https://github.com/user-attachments/assets/bbfa8d46-f3fb-48df-83e7-c5485dda2eec" />
<br>
The rest of the code I used to get these scores can be found in the SQL section of this project, linked here:  
<br>
<br>

[SQL_Growth](04_Growth%20Calculation.sql)  
[SQL_Scoring](05_Scoring.sql)  
___

## **Results and Observations:**

Before we continue, I want to see if there is a relationship between average dosage cost and beneficiaries/claims. I'll use scatterplots to show the output between claims/beneficiaries and average dosage price.

<img width="1062" height="277" alt="Screenshot 2026-07-08 105657" src="https://github.com/user-attachments/assets/0337c56b-4b51-4076-ac19-afbdea7b0a01" />
<br>
From this, it can be concluded that there isn't a very strong correlation between average price per dose and number of claims/beneficiaries. It's more of a case by case basis. There is a near linear correlation between claims and beneficiaries which is obvious, I wanted to check to confirm whether I could use them interchangeably.

&nbsp;

- If a policy requires removal or tier adjustment of medications based on overall score for the most recent year in the data (2023), these would be the top 10 candidates:
  
<img width="1277" height="275" alt="Screenshot 2026-07-08 103517" src="https://github.com/user-attachments/assets/b1b1bfe5-6b94-4a5e-a855-070c966a3b5b" />
<br>
<br>

- If a policy requires tier adjustment of medications due to high dosage prices AND high number of beneficiaries for the most recent year in the data (2023), these would be the top 10 candidates.

<img width="1282" height="317" alt="Screenshot 2026-07-08 103535" src="https://github.com/user-attachments/assets/8440b4c5-1a18-4b28-b895-571a0831a053" />
<br>
<br>

- I standardized the data using the percent rank composite score so the visuals look more balanced, but I wanted to mention some dosage price outliers here. When using the raw numbers, it's clear that Kymriah, Yescarta, Breyanzi, Tecartus, Carvykti and Provenge are extreme outliers in terms of pricing. I pointed this out briefly in the Python outlier section, but I also wanted to reference it here. If a MA policy is being evaluated for formulary adjustment and it covers any of these medication, they should have increased priority for removal.

<div align="center">
	
<img width="876" height="267" alt="Screenshot 2026-07-08 104007" src="https://github.com/user-attachments/assets/15f0a2bb-8cd2-4b50-8643-8b223143c207" />

</div>

<br>

- In terms of 2021-2022 growth and 2022-2023 growth metrics, these are the top medications to keep an eye on. Anything in the center tables had a very high growth percentage.

<img width="1172" height="660" alt="image" src="https://github.com/user-attachments/assets/7277bfc3-5932-43b8-b777-780a0e284c66" />
___

## **Analyst Notes and Recommendations:**

- The scoring system is simple: **The higher the score, the more liable the medication is for causing losses.** I showed the top 10 items for each data question in the previous section, but the dashboard list contains all medications and their respective attribute scores and final composite score. Should a policy need modification beyond the scope of the top 10, simply go down the list and see which medications are the most appropriate for removal. You can also manually search specific medications and years using the search bar at the top.
  
- Before **removing** a medication, ensure that it has an alternative for whatever it is used to treat. For example, if you notice a drug meant to treat exzema has few beneficiaries and costs a lot to cover, ensure there are other drugs in the formulary that treat exzema before removing it. If there is no alternative, then it may be sufficient to move it up a tier instead.

- Before adjusting a medication, be sure to verify whether it is an outlier. **Outliers are marked in yellow on the dashboard**. If a medication is an outlier for the specified year, look into that medication to verify whether it was only a liability for that year, or if it's been a liability for multiple years.

- This dashboard list should be updated with fresh data annually. As long as the data schema is maintained, it can be sent through the pipeline found in each part of the project (Python -> SQL -> Power BI). It will score the medications and organize them by liability.
