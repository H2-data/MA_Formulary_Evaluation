<div align="center">

# Medicare Advantage Formulary Evaluation

</div>

---

### **Important Notes:**

- The data used in this project is a public dataset, it is not confidential data.

- Files are labelled from 01-05. They can be read in numeric order. The dashboard is screenshotted and linked below, and it is the last step in the process.

### **Scenario and Objective:**

Alpha Green Insurance LLC (Not a real company) wants to make changes to their formulary for select Medicare Advantage policies and supplements in 2024. They have asked me to look over the formulary data for the previous years to get a feel for the territory, and create a list of medications that can be reliably removed from a formulary. My goal is to answer the following business question:

- Which medications can be either removed from a formulary or moved into a higher medication tier to reduce losses on select policies?

I will translate this business question into data questions:

- Which medications have the **fewest beneficiaries** and **high costs**? Medications like these can safely be removed from a formulary or increased by a tier.

- Which medications have both a **high price** and a **high number of claims and beneficiaries**? It is unsafe to completely remove medications like these, but increasing their tier could reduce overall losses.

### **Data Report:**

<img width="1193" height="668" alt="image" src="https://github.com/user-attachments/assets/b2ba68b0-42a2-4f25-b88e-8d3d6dec5553" />
<br>
To interact with the dashboard or search for individual medication scores, see the Power BI section of the project, linked here:  
<br>
<br>

[Dashboard](https://app.powerbi.com/view?r=eyJrIjoiZmYyYzJiNDctOTI1Ny00NDRiLWE5OTItODI5NDc0M2U1ZjE0IiwidCI6ImRmZWM4YzJjLThlNWUtNDI4Yy05MmE4LTkzOTI1ZjM3Y2JlYiJ9)

### **Data Preprocessing:**

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

### **How can I solve the problem?**

After trying a couple of different methods, I believe the most effective way to decide which medications incur the most losses is using a Weighted Composite Score since there are multiple factors that determine whether a medication is a liability. I will use 5 factors to score a medication:

- Average Spending (30%), the higher the price, the higher score
- Total Beneficiaries (inverted) (25%), the lower the number of beneficiaries, the higher the score
- Total Claims (inverted) (25%), the lower the number of claims, the higher the score
- 2022-2023 Spending Change (15%), the higher the growth, the higher the score
- 2021-2022 Spending Change (5%), the higher the growth, the higher the score

The following is a snippet of the resulting output. To keep things clean, I used Percent Rank as the standardization method, meaning each medication is ranked a number from 0 to 1 depending on it's overall score. The higher the score, the more likely the medication is a liability. I also kept the original scores for each category for later plotting.

```SQL
SELECT
	Brnd_Name as Medication,
	Outlier_Flag as Outlier_Flag,
    ROUND(composite_score, 2) as Score
FROM final_scores
WHERE YEAR = 2023
ORDER BY composite_score DESC
LIMIT 5;
```
<img width="492" height="132" alt="image" src="https://github.com/user-attachments/assets/48770bac-28a1-43d4-bfaf-67aaddf4a462" />
<br>
The rest of the code I used to get these scores can be found in the SQL section of this project, linked here:  
<br>
<br>

[SQL_Imports](02_Importing.sql)  
[SQL_Nulls](03_Nulls.sql)  
[SQL_Growth](04_Growth%20Calculation.sql)  
[SQL_Scoring](05_Scoring.sql)  

### **Results and Observations:**

Before we continue, I want to see if there is a relationship between average dosage cost and beneficiaries/claims. I'll use scatterplots to show the output between claims/beneficiaries and average dosage price.

<img width="1078" height="326" alt="image" src="https://github.com/user-attachments/assets/56e0dcfe-2ecb-48c9-85c6-95db9475aff2" />
<br>
From this, it can be concluded that there isn't a very strong correlation between average price per dose and number of claims/beneficiaries. It's more of a case by case basis. There is a near linear correlation between claims and beneficiaries which is obvious, I wanted to check to confirm whether I could use them interchangeably.

&nbsp;

- If a policy requires removal or tier adjustment of medications based on overall score for the most recent year in the data (2023), these would be the top 10 candidates:
  
<img width="1176" height="258" alt="image" src="https://github.com/user-attachments/assets/ebbb16bf-5b69-4bd8-84d8-0ec1cb7bff63" />
<br>
<br>

- If a policy requires tier adjustment of medications due to high dosage prices AND high number of beneficiaries for the most recent year in the data (2023), these would be the top 10 candidates.

<img width="1172" height="276" alt="image" src="https://github.com/user-attachments/assets/3fd6f8d3-624b-4afa-bd60-828e7659064a" />
<br>
The rest of the dashboard as well as the scores for all other medications can be found in the Power BI section of this project, linked here:
<br>
<br>

[Dashboard](https://app.powerbi.com/view?r=eyJrIjoiZmYyYzJiNDctOTI1Ny00NDRiLWE5OTItODI5NDc0M2U1ZjE0IiwidCI6ImRmZWM4YzJjLThlNWUtNDI4Yy05MmE4LTkzOTI1ZjM3Y2JlYiJ9)

### **Analyst Recommendations:**

- The scoring system is simple: **The higher the score, the more liable the medication is for causing losses.** I showed the top 10 items for each data question in the previous section, but the dashboard list contains all medications and their respective attribute scores and final composite score. Should a policy need modification beyond the scope of the top 10, simply go down the list and see which medications are the most appropriate for removal. You can also manually search specific medications and years using the search bar at the top.
  
- Before **removing** a medication, ensure that it has an alternative for whatever it is used to treat. For example, if you notice a drug meant to treat exzema has few beneficiaries and costs a lot to cover, ensure there are other drugs in the formulary that treat exzema before removing it. If there is no alternative, then it may be sufficient to move it up a tier instead.

- Before adjusting a medication, be sure to verify whether it is an outlier. **Outliers are marked in yellow on the dashboard**. If a medication is an outlier for the specified year, look into that medication to verify whether it was only a liability for that year, or if it's been a liability for multiple years.

- This dashboard list should be updated with fresh data annually. As long as the data schema is maintained, it can be sent through the pipeline found in each part of the project (Python -> SQL -> Power BI). It will score the medications and organize them by liability.
