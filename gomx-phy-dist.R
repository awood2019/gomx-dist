#analyzing proportion of different phyla in each GoM sample as it relates to depth and location

#install packages using BiocManager
library(BiocManager) #needed to install phyloseq
BiocManager::install('phyloseq', force = TRUE)
BiocManager::install('DESeq2', force = TRUE)
BiocManager::install('dendextend')

#load packages
library(tidyverse) ; packageVersion("tidyverse") 
library(phyloseq) ; packageVersion("phyloseq") 
library(vegan) ; packageVersion("vegan") 
library(DESeq2) ; packageVersion("DESeq2") 
library(dendextend) ; packageVersion("dendextend") 
library(viridis) ; packageVersion("viridis") 
library("ggplot2")

#set working directory 
setwd("~/Desktop/AW RStudio/data/gomx-phy-dist")


#---------phyloseq--------

#load components of phyloseq object: taxonomy table, count table, and sample data table
tax_tab <- read_csv("rep-seqs-phylum.csv", show_col_types = FALSE) #loading taxonomy table w/ ASVs, sequence, & phyla
count_tab <- read_delim("table.tsv") #loading count table w/ ASV counts for each sample
sample_info_tab <- read_csv("anth-28S-sampledata_20231016.csv") #loading sample data table w/ sample metadata

#coerce tables into proper format to make phyloseq object
#tax_tab_phy: includes taxonomic information for each representative (ASV) sequence
phylum <- tax_tab$Phylum #pulling out phylum column from taxonomy table
tax_tab_phy <- tibble(phylum) #making phyla into a tibble containing phylum for each sequence
tax_tab_phy <- as.matrix(tax_tab_phy) #make tibble into matrix
row.names(tax_tab_phy) <- tax_tab$Sequence #make sequence column the row names
tax_tab_phy[is.na(tax_tab_phy)] <- "< 85% similarity to top BLAST hit" #change NA values to more accurate description

#count_tab_phy: includes all ASVs and their abundances in each sample (row.names must match row.names of tax_tab_phy)
count_tab_phy <- select(count_tab, -"...1") #delete this weird column
row.names(count_tab_phy) <- count_tab$...1 #make sequences the row names (ignore warning message)

#sample_info_tab_phy: table that includes sample information for all samples (row.names must equal col.names in count table)
sample_info_tab <- sample_info_tab %>% mutate(depth_bin = cut_width(sample_info_tab$Depth, width = 10, boundary = 0)) #create column for depth range as a factor
sample_info_tab_phy <- sample_info_tab
sample_info_tab_phy <- sample_info_tab_phy[-c(55,56),] #delete the last 2 rows because they have NAs across the board
sample_data <- sample_data(sample_info_tab_phy) #convert to phyloseq component now because row names get changed by sample_data command
row.names(sample_data) <- sample_data$File.name #change row names to match file name

#make phyloseq object 
ASV_physeq <- phyloseq(otu_table(count_tab_phy, taxa_are_rows = TRUE), tax_table(tax_tab_phy), sample_data)
ASV_physeq <- prune_taxa(taxa_sums(ASV_physeq) > 0, ASV_physeq) #pruning out ASVs with zero counts
saveRDS(ASV_physeq, 'allphy_physeq.rds') #save phyloseq object

#transform phyloseq object to dataframe 
df_ASV_physeq <- ASV_physeq %>% psmelt() #melt phyloseq object to long dataframe
head(df_ASV_physeq)

#---------bar plotting results---------

#plotting phyla distribution at Bright Bank by depth and method
#creating dataframe for phyla distribution
df_site_bb <- df_ASV_physeq %>% 
  filter(Site == "Bright Bank") %>% #select only ASVs collected at Bright Bank
  filter(CTD.ROV != "Negative" & CTD.ROV != "NTC") #remove blank and control samples

#plot Bright Bank object for phyla distribution by depth faceted by collection method
ggplot(df_site_bb, aes(x=depth_bin, y = Abundance, fill = phylum)) + #x-axis = depth, y-axis = ASV abundance
  geom_bar(position="fill", stat = "identity") + #position=fill graphs abundance as a proportion out of the total, stat=identity tells ggplot to calculate sum of the y var grouped by the x var
  facet_grid(.~CTD.ROV, scale = "free_x", space = "free_x") + #facet by collection method and scale x axis freely so labels don't overlap
  ylab("Percentage of ASVs recovered") + 
  xlab("Depth (m)") +
  ggtitle("Phyla Distribution at Bright Bank")+
  theme_classic() +
  scale_fill_viridis(discrete=TRUE, option="turbo") 

#plotting phyla distribution at Viosca Knoll by depth and method
#creating dataframe for phyla distribution
df_site_vk <- df_ASV_physeq %>% 
  filter(Site == "Viosca Knoll") %>% #select only ASVs collected at Viosca Knoll
  filter(CTD.ROV != "Negative" & CTD.ROV != "NTC") #remove blank and control samples

#plot Viosca Knoll object for phyla distribution by depth faceted by collection method
ggplot(df_site_vk, aes(x=depth_bin, y = Abundance, fill = phylum)) + #x-axis = depth, y-axis = ASV abundance
  geom_bar(position="fill", stat = "identity") + #position=fill graphs abundance as a proportion out of the total, stat=identity tells ggplot to calculate sum of the y var grouped by the x var
  facet_grid(.~CTD.ROV, scale = "free_x", space = "free_x") + #facet by collection method and scale x axis freely so labels don't overlap
  ylab("Percentage of ASVs recovered") +
  xlab("Depth (m)") +
  ggtitle("Phyla Distribution at Viosca Knoll") +
  theme_classic() +
  scale_fill_viridis(discrete=TRUE, option="turbo") 


#-----------------

#plotting phyla distribution w/ phyloseq objects - can delete probably but keeping for a bit just in case
#creating object for phyla distribution
site_bb = ASV_physeq_rel %>% #select phyloseq object
  subset_samples(Site == "Bright Bank") %>% #select only samples collected at Bright Bank
  subset_samples(CTD.ROV != "Negative" & CTD.ROV != "NTC") #select only samples collected by CTD and ROV

#plot Bright Bank object for phyla distribution by depth faceted by collection method
site_bb_labs <- c("0-10", "40-50", "60-70", "70-80", "80-90", "60-70", "80-90", "110-120")
plot_bar(site_bb, x= "depth_bin", fill = "phylum", title = "Phyla Distribution at Bright Bank") + #x-axis is depth, bars are percentage of phyla
  facet_grid(~CTD.ROV, scale = "free_x", space = "free_x") + #facet by collection method, x-axis scale is free
  labs(y = "Percentage of ASVs recovered", x = "Depth range (m)") + #name axes
  geom_bar(stat = "identity") + #get rid of black bars
  theme_classic() + #set theme
  scale_fill_viridis(discrete=TRUE, option="turbo") +  #set color palette
  scale_x_discrete(labels=site_bb_labs) #set x axis values to be more aesthetic

#plotting phyla distribution at Viosca Knoll by depth and method
site_vk = ASV_physeq_rel %>% #select phyloseq object
  subset_samples(Site == "Viosca Knoll") %>% #select only samples collected at Viosca Knoll
  subset_samples(CTD.ROV != "Negative" & CTD.ROV != "NTC") #select only samples collected by CTD and ROV

#plot Viosca Knoll object for phyla distribution by depth faceted by collection method
site_vk_labels <- c("440-450", "450-460", "460-470", "470-480")
plot_bar(site_vk, x= "depth_bin", fill = "phylum", title = "Phyla Distribution at Viosca Knoll") + #x-axis is depth, bars are percentage of phyla
  facet_grid(~CTD.ROV, scale = "free_x", space = "free_x") + #facet by collection method, x-axis scale is free
  labs(y = "Percentage of ASVs recovered", x = "Depth range (m)") + #name axes
  geom_bar(stat="identity") + #get rid of black bars
  theme_classic() + #set theme
  scale_fill_viridis(discrete=TRUE, option="turbo") + #set color palette
  scale_x_discrete(labels=site_vk_labels) #set x axis values to be more aesthetic



