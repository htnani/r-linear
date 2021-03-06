


#////////////////////////
# 1 Loading packages ----

knitr::opts_chunk$set(fig.align="center", fig.width=5,fig.height=5)

# To install needed packages:
#   install.packages("tidyverse")
#   install.packages("multcomp")

library(tidyverse)
library(multcomp)

# Much of what we will be using is built in to R without loading any
# packages.
#
# From the [Tidyverse](https://www.tidyverse.org/) we will be using:
#
# * readr::read_csv as a convenient way to specify a data frame.
# * dplyr for data frame manipulations.
# * ggplot2 for graphing.
#
# See [here](https://monashbioinformaticsplatform.github.io/r-more/topic
# s/tidyverse.html) for our introduction to the Tidyverse.
#
# We will also be using:
#
# * multcomp::glht to calculate contrast p-values and confidence
# intervals.



#////////////////////////////
# 2 Vectors and matrices ----

# 2.1 Vector operations ----

a <- c(3,4)
b <- c(5,6)

length(a)

# R performs operations elementwise:

a + b
a * b

# We will be using the dot product a lot. This is:

sum(a*b)

# The *geometric* length of a vector is (by Pythagorus):

sqrt(sum(a*a))
sqrt(sum(a^2))

# 2.2 Matrix operations ----
#
# We can create a matrix with matrix, rbind (row bind), or cbind (column
# bind).

matrix(c(1,2,3,4), nrow=2, ncol=2)
rbind(c(1,3), c(2,4))
cbind(c(1,2), c(3,4))

X <- rbind(
    c(1,0),
    c(1,0),
    c(1,1),
    c(1,1))
X
class(X)

# The matrix transpose is obtained with t.

t(X)

# Matrix multiplication is performed with %*%. The dot product of each
# row of the left hand side matrix and each column of the right hand
# side matrix is calculated. %*% treats a vector as a single column
# matrix. Actually all we need today is to multiply a matrix by a
# vector, in which case we get the dot product of each row of the matrix
# with the vector.

X %*% a
as.vector(X %*% a)



#//////////////////////////////////
# 3 Single numerical predictor ----
#
# The age (year) and height (cm) of 10 people has been measured. We want
# a model that can predict height based on age.

people <- read_csv(
    "age, height
      10,    131
      14,    147
      16,    161
       9,    136
      16,    170
      15,    160
      15,    153
      21,    187
       9,    145
      21,    195")

ggplot(people, aes(x=age, y=height)) + geom_point()

fit <- lm(height ~ age, data=people)

fit

# Coefficients are extracted with coef:

coef(fit)

# The residual standard deviation is extracted with sigma:

sigma(fit)

# Behind the scenes a matrix of predictors has been produced from the
# mysterious notation ~ age. We can examine it explicitly:

model.matrix(fit)

# model.matrix can be used without first calling lm.

model.matrix(~ age, data=people)

# 10 observations minus 2 columns in the model matrix leaves 8 residual
# degrees of freedom:

df.residual(fit)

# 3.1 Prediction ----
#
# predict predicts. By default it produces predictions on the original
# dataset.

predict(fit)
predict(fit, interval="confidence")

# We can also calculate predictions manually.

X <- model.matrix(fit)
beta <- coef(fit)
as.vector( X %*% beta )

# predict can be used with new data.

new_people <- data_frame(age=5:25)
predict(fit, new_people)

new_predictions <- cbind(
    new_people,
    predict(fit, new_people, interval="confidence"))

ggplot() +
    geom_ribbon(aes(x=age, ymin=lwr, ymax=upr), data=new_predictions, fill="grey") +
    geom_line(aes(x=age, y=fit), data=new_predictions, color="blue") +
    geom_point(aes(x=age, y=height), data=people) +
    labs(y="height (cm)", x="age (year)",
         subtitle="Ribbon shows 95% confidence interval of the model")

# If you have ever used geom_smooth, it should now be a little less
# mysterious.

ggplot(people, aes(x=age, y=height)) + geom_smooth(method="lm") + geom_point()

# 3.2 Residuals ----
#
# The residuals are the differences between predicted and actual values.

residuals(fit)

plot(predict(fit), residuals(fit))

# Residuals should be close to normally distributed.

qqnorm(residuals(fit))
qqline(residuals(fit))

# Ideally the points would lie on the line. Are they far enough away to
# worry about? We can simulate some data to judge against.
# Try this several times:

sim <- rnorm(10, mean=0, sd=sigma(fit))
qqnorm(sim)
qqline(sim)

# plot(fit) produces a series of more sophisticated diagnostic plots.

plot(fit)



#///////////////////////////////////////////
# 4 Single factor predictor, two levels ----
#
# Consider a simple experiment where some outcome is measured for an
# untreated and a treated group. This can be viewed as a one-way
# ANalysis Of Variance (ANOVA) experiment. (This is one of two senses in
# which the term ANOVA will be used today.)

outcomes <- read_csv(
       "group, outcome
    untreated,  4.98
    untreated,  5.17
    untreated,  5.66
    untreated,  4.87
      treated,  8.07
      treated, 11.02
      treated,  9.91")

outcomes$group <- factor(outcomes$group, c("untreated", "treated"))

outfit <- lm(outcome ~ group, data=outcomes)
outfit

df.residual(outfit)
sigma(outfit)

model.matrix(outfit)

# 4.1 Challenge - the meanings of coefficients ----
#
# Examine the model matrix. What are the meanings of the two
# coefficients that have been fitted?
#
# Suppose instead we fit:

outfit2 <- lm(outcome ~ 0 + group, data=outcomes)

# What do the coefficients in this new model represent? Does it fit the
# data better or worse than the original model?
#
# 4.2 Testing a hypothesis ----
#
# Besides data with categorical predictors, the term ANOVA is used to
# refer to the use of the F test. Significance is judged based on
# comparing the Residual Sums of Squares of two models. We fit a model
# representing a null hypothesis. This model formula must nest within
# our original model formula: any prediction it can make can also be
# made by the original model formula. We compare the models using the
# anova function.

outfit0 <- lm(outcome ~ 1, data=outcomes)

anova(outfit0, outfit)

# **Warning:** This is not the only way to use the anova( ) function,
# but I think this is the safest way. Once we start using multiple
# predictors, the meaning of the output from anova with a single model
# is likely to be not quite what you want. Read the documentation
# carefully. The aov( ) function also has traps for the unwary. Use lm(
# ), and anova( ) with two nested models as in this document and the
# meaning should be as you would expect.
#
# summary( ) also outputs p-values. Too many p-values, summary( )
# doesn't respect the hierarchy of terms in the model. The p-value for
# dropping the intercept is nonsense.

summary(outfit)

# confint( ) tells us not only that the difference between groups is
# non-zero but places a confidence interval on the difference. If the
# p-value were 0.05, the confidence interval would just touch zero.
# Whenever we reject a hypothesis that a single coefficient is zero, we
# may also conclude that we know its sign.

confint(outfit)

# These results exactly match those of a t-test.

t.test(outcome ~ group, data=outcomes, var.equal=TRUE)

# 4.3 Challenge - does height change with age? ----
#
# Return to the people dataset. Can we reject the hypothesis that height
# is unrelated to age?
#
# Compare the result to the outcome of a correlation test using
# cor.test( ).
#


#/////////////////////////////////////
# 5 Multiple factors, many levels ----
#
# Particle sizes of PVC plastic produced by a machine are measured. The
# machine is operated by three different people, and eight different
# batches of resin are used. Two measurements are made for each
# combination of these two experimental factors.
#
# (This example is adapted from a data-set in the faraway package.)

pvc <- read_csv("r-linear-files/pvc.csv")
pvc$operator <- factor(pvc$operator)
pvc$resin <- factor(pvc$resin)

ggplot(pvc, aes(x=resin, y=psize)) + geom_point() + facet_grid(~operator)

# 5.1 Main effects ----

pvcfit1 <- lm(psize ~ operator + resin, data=pvc)

summary(pvcfit1)
confint(pvcfit1)

# 5.2 Heteroscedasticity ----

ggplot(pvc, aes(x=resin, y=residuals(pvcfit1))) +
    geom_point() + geom_hline(yintercept=0) + facet_grid(~operator)

# Our assumption that the residual noise is uniformly normally
# distributed may not hold. Carl's data seems to have greater standard
# deviation than Alice or Bob's. When comparing Alice and Bob's results,
# including Carl's data in the model may alter the outcome.

# 5.3 Interactions ----

pvcfit2 <- lm(psize ~ operator + resin + operator:resin, data=pvc)
# or
pvcfit2 <- lm(psize ~ operator*resin, data=pvc)

anova(pvcfit1, pvcfit2)

# 5.4 Contrasts and confidence intervals ----
#
# anova lets us test if a particular factor interaction is needed at
# all, and summary allows us to see if any levels of a factor differ
# from the first level. However we may wish to compare an arbitrary pair
# of levels in a factor, or even some more complicated combination of
# levels. This can be done using contrasts.
#
# Say we want to compare Bob and Carl's particle sizes. We will use the
# pvcfit model as a starting point.

coef(pvcfit1)
K <- rbind(Carl_vs_Bob = c(0, -1,1, 0,0,0,0,0,0,0))

K %*% coef(pvcfit1)

# This is the estimated difference in particle size between Carl and
# Bob, but can we trust it? The glht function from multcomp can tell us.
# GLHT stands for General Linear Hypothesis Test, "general" meaning it
# can be used with various other types of models besides plain linear
# models.

result <- glht(pvcfit1, K)
result
summary(result)
confint(result)

# glht can test multiple contrasts at once. By default it applies a
# multiple testing correction when doing so. This is a generalization of
# Tukey's Honestly Significant Differences.

K <- rbind(
    Bob_vs_Alice  = c(0,  1,0, 0,0,0,0,0,0,0),
    Carl_vs_Alice = c(0,  0,1, 0,0,0,0,0,0,0),
    Carl_vs_Bob   = c(0, -1,1, 0,0,0,0,0,0,0))
result <- glht(pvcfit1, K)
summary(result)
confint(result)

# We can also turn off the multiple testing correction.

summary(result, test=adjusted("none"))

# A reasonable compromise between these extremes is Benjamini and
# Hochberg's False Discovery Rate (FDR) correction.

summary(result, test=adjusted("fdr"))

# Finally, we can ask if *any* of the contrasts is non-zero, i.e.
# whether the model with all three constraints applied can be rejected.
# This is equivalent to the anova( ) tests we have done earlier. (Note
# that while we have three constraints, the degrees of freedom reduction
# is 2, as any 2 of the constraints are sufficient. This makes me
# uneasy, it's reliant on numerical accuracy.)

summary(result, test=Ftest())

pvcfit0 <- lm(psize ~ resin, data=pvc)
anova(pvcfit0, pvcfit1)

# This demonstrates that the two methods of testing hypotheses--with the
# ANOVA test and with contrasts--are equivalent.



#///////////////////////////////
# 6 Gene expression example ----
#
# Tooth growth in mouse embryos is studied using RNA-Seq. The RNA
# expression levels of several genes are examined in the cells that form
# the upper and lower first molars, in eight individual mouse embryos
# that have been disected after different times of embryo development.
# The measurements are in terms of "Reads Per Million", essentially the
# fraction of RNA in each sample belonging to each gene, times 1
# million.
#
# (This data was extracted from ARCHS4. In the Gene Expression Omnibus
# (GEO), it is entry GSE76316. The sample descriptions in GEO seem to be
# out of order, but reading the associated paper and the genes they talk
# about I *think* I now have the correct order of samples.)

teeth <- read_csv("r-linear-files/teeth.csv")

# It will be convenient to have a quick way to examine different genes
# and different models with this data.

# A convenience to examine different model fits
more_data <- expand.grid(
        day=seq(14.3,18.2,by=0.01),
        tooth=as_factor(c("lower","upper"))) %>%
    mutate(mouse=paste0("ind",round((day-14.5)*2+1)))

look <- function(y, fit=NULL) {
    p <- ggplot(teeth,aes(x=day,group=tooth))
    if (!is.null(fit)) {
        more_ci <- cbind(more_data, predict(fit, more_data, interval="confidence"))
        p <- p +
            geom_ribbon(data=more_ci, aes(ymin=lwr,ymax=upr),alpha=0.1) +
            geom_line(data=more_ci,aes(y=fit,color=tooth))
    }
    p + geom_point(aes(y=y,color=tooth))
}

# Try it out
look(teeth$gene_ace)

# We could treat day as a categorical variable, as in the previous
# section. However let us treat it as numerical, and see where that
# leads.

# 6.1 Transformation ----

# 6.1.1 Ace gene ----

acefit <- lm(gene_ace ~ tooth + day, data=teeth)

look(teeth$gene_ace, acefit)

# Two problems:
#
# 1. The actual data appears to be curved, our straight lines are not a
# good fit.
# 2. The predictions fall below zero, a physical impossibility.
#
# In this case, log transformation of the data will solve both these
# problems.

log2_acefit <- lm( log2(gene_ace) ~ tooth + day, data=teeth)

look(log2(teeth$gene_ace), log2_acefit)

# Various transformations of y are possible. Log transformation is
# commonly used in the context of gene expression. Square root
# transformation can also be appropriate with nicely behaved count data
# (technically, if the errors follow a Poisson distribution). This gene
# expression data is ultimately count based, but is overdispersed
# compared to the Poisson distribution so square root transformation
# isn't appropriate in this case. The Box-Cox transformations provide a
# spectrum of further options.

# 6.1.2 Pou3f3 gene ----
#
# In the case of the Pou3f3 gene, the log transformation is even more
# important. It looks like gene expression changes at different rates in
# the upper and lower molars, that is there is a significant interaction
# between tooth and day.

pou3f3fit0 <- lm(gene_pou3f3 ~ tooth + day, data=teeth)
pou3f3fit1 <- lm(gene_pou3f3 ~ tooth * day, data=teeth)

anova(pou3f3fit0, pou3f3fit1)

look(teeth$gene_pou3f3, pou3f3fit0)
look(teeth$gene_pou3f3, pou3f3fit1)

# Examining the residuals reveals a further problem.

look(residuals(pou3f3fit1))
plot(predict(pou3f3fit1), residuals(pou3f3fit1))
qqnorm(residuals(pou3f3fit1))
qqline(residuals(pou3f3fit1))

# Larger expression values are associated with larger residuals.
#
# Log transformation both removes the interaction and makes the
# residuals more uniform (except for one outlier).

log2_pou3f3fit0 <- lm(log2(gene_pou3f3) ~ tooth + day, data=teeth)
log2_pou3f3fit1 <- lm(log2(gene_pou3f3) ~ tooth * day, data=teeth)

anova(log2_pou3f3fit0, log2_pou3f3fit1)

look(log2(teeth$gene_pou3f3), log2_pou3f3fit0)

qqnorm(residuals(log2_pou3f3fit0))
qqline(residuals(log2_pou3f3fit0))

# 6.2 Curve fitting ----

# 6.2.1 Smoc1 gene ----

log2_smoc1fit <- lm( log2(gene_smoc1) ~ tooth + day, data=teeth)

look(log2(teeth$gene_smoc1), log2_smoc1fit)

# In this case, log transformation does not remove the curve. If you
# think this is a problem for *linear* models, you are mistaken! With a
# little *feature engineering* we can fit a quadratic curve.
# Calculations can be included in the formula if wrapped in I( ):

curved_fit <- lm(log2(gene_smoc1) ~ tooth + day + I(day^2), data=teeth)
look(log2(teeth$gene_smoc1), curved_fit)

# Another way to do this would be to add the column to the data frame:

teeth$day_squared <- teeth$day^2
curved_fit2 <- lm(log2(gene_smoc1) ~ tooth + day + day_squared, data=teeth)

# Finally, the poly( ) function can be used in a formula to fit
# polynomials of arbitrary degree. poly will encode day slightly
# differently, but produces an equivalent fit.

curved_fit3 <- lm(log2(gene_smoc1) ~ tooth + poly(day,2), data=teeth)

sigma(curved_fit)
sigma(curved_fit2)
sigma(curved_fit3)

# poly can also be used to fit higher order polynomials, but these tend
# to become very wobbly and extrapolate poorly. A better option may be
# to use the ns( ) or bs( ) functions in the splines package, which can
# be used to fit piecewise "B-splines". In particular ns( ) (natural
# spline) is appealing because it extrapolates beyond the ends only with
# straight lines. If the data is cyclic (for example cell cycle or
# circadian time series), sine and cosine terms can be used to fit some
# number of harmonics from a Fourier series.

library(splines)
spline_fit <- lm(log2(gene_smoc1) ~ tooth * ns(day,3), data=teeth)

look(log2(teeth$gene_smoc1), spline_fit)

# 6.3 Day is confounded with mouse ----
#
# There may be individual differences between mice. We would like to
# take this into our account in a model. In general it is common to
# include batch effect terms in a model in order to correctly model the
# data (and increase the significance level of results), even if they
# are not directly of interest.

badfit <- lm(log2(gene_ace) ~ tooth + day + mouse, data=teeth)
summary(badfit)

# In this case this is not possible. As a different mouse produced data
# for each different day, mouse is confounded with day. day can be
# constructed as a linear combination of the intercept term and the
# mouse terms.
#
# Another example of confounding would be an experiment in which each
# treatment is done in a separate batch.
#
# Highly correlated predictors can also be problematic, even if not
# perfectly confounded.
#
# A possible solution to this problem would be to use a "mixed model",
# but this is beyond the scope of today's workshop.



#/////////////////////////////////////
# 7 Testing many genes with limma ----

# 7.1 Load, normalize, log transform ----
#
# Actually in this gene expression dataset, the expression level of all
# genes was measured!

counts_df <- read_csv("r-linear-files/teeth-read-counts.csv")

counts <- counts_df %>%
    column_to_rownames("gene") %>%
    as.matrix()

counts[1:5,]

# The column names match our teeth data frame.

teeth$sample

# A usual first step in RNA-Seq analysis is to convert read counts to
# Reads Per Million, and log2 transform the results. There are some
# subtlties here which we breeze over lightly: We use "TMM"
# normalization as a small adjustment to the total number of reads in
# each sample. A small constant is added to the counts to avoid
# calculating log2(0). The edgeR and limma manuals describe these in
# more detail.

library(edgeR)
library(limma)

dgelist <- calcNormFactors(DGEList(counts))

dgelist$samples

log2_cpms <- cpm(dgelist, log=TRUE, prior.count=0.25)

# There is little chance of detecting differential expression in genes
# with very low read counts. Including these genes will require a larger
# False Discovery Rate correction, and also confuses limma's Empirical
# Bayes hyper-parameter estimation. Let's only retain genes with an
# average of 5 reads per sample or more.

keep <- rowMeans(log2_cpms) >= -3
log2_cpms_filtered <- log2_cpms[keep,]

nrow(log2_cpms)
nrow(log2_cpms_filtered)

# 7.2 Fitting a model to and testing each gene ----
#
# We will use limma to fit a linear model to each gene. The same model
# formula will be used in each case.
#
# limma doesn't automatically convert a formula into a model matrix, so
# we have to do this step manually. Here I am using a model formula that
# treats day/mouse as categorical, so this will be like our earlier pvc
# example. The models treating day as a numeric variable are just as
# applicable (this is left as an exercise).

design <- model.matrix(~ tooth + mouse, data=teeth)

fit <- lmFit(log2_cpms_filtered, design)

class(fit)
fit$coefficients[1:5,]

# Significance testing in limma is by the use of contrasts. A difference
# between glht and limma's contrasts.fit is that limma uses columns as
# contrasts, rather than rows.

K <- rbind(upper = c(0, 1, 0,0,0,0,0,0,0))
cfit <- contrasts.fit(fit, t(K))

# Empirical Bayes squeezing of the residual variance acts as though we
# have some number of extra "prior" observations of the variance. These
# are also counted as extra degrees of freedom in F tests. The "prior"
# observations act to squeeze the estimated residual variance toward a
# trend line that is a function of the average expression level.

efit <- eBayes(cfit, trend=TRUE)
efit$df.prior
plotSA(efit)
points(efit$Amean, efit$s2.post^0.25, col="red", cex=0.3)

topTable(efit)

all_results <- topTable(efit, n=Inf)

significant <- all_results$adj.P.Val <= 0.05
table(significant)

ggplot(all_results, aes(x=AveExpr, y=logFC)) +
    geom_point(size=0.1, color="grey") +
    geom_point(data=all_results[significant,], size=0.1)

# 7.3 Relation to lm( ) and glht( ) ----
#
# Nkx2-3 stands out in terms log2 fold change.

nkx23 <- log2_cpms["Nkx2-3",]
nkx23_fit <- lm(nkx23 ~ tooth + mouse, data=teeth)
look(nkx23, nkx23_fit)

# We can use the same contrast with glht. The value of the contrast is
# the same, but limma has gained some power by shrinking the variance
# toward the trend line, so limma's p-value is smaller.

summary( glht(nkx23_fit, K) )

# 7.4 False Coverage Rate corrected CIs ----
#
# Confidence Intervals should also be of interest.

topTable(efit, confint=0.95)

# However we should adjust for multiple testing. A False Coverage Rate
# corrected CI can be constructed corresponding to a set of genes judged
# significant. The smaller the selection of genes as a proportion of the
# whole, the greater the correction required. To ensure a false coverage
# rate of q, we use the confidence interval
# (1-q*n_genes_selected/n_genes_total)*100%.

all_results <- topTable(efit, n=Inf)
significant <- all_results$adj.P.Val <= 0.05
prop_significant <- mean(significant)
fcr_confint <- 1 - 0.05*prop_significant

all_results <- topTable(efit, confint=fcr_confint, n=Inf)

ggplot(all_results, aes(x=AveExpr, y=logFC)) +
    geom_point(size=0.1, color="grey") +
    geom_errorbar(data=all_results[significant,], aes(ymin=CI.L, ymax=CI.R), color="red") +
    geom_point(data=all_results[significant,], size=0.1)

# The FCR corrected CIs used here have the same q, 0.05, as we used as
# the cutoff for adj.P.Val. This means they never pass through zero.

# 7.5 ANOVA test ----
#
# limma can also test a constraint over several contrasts at once. We
# illustrate this verbosely:

K2 <- rbind(
    ind2_vs_ind1 = c(0, 0, 1,0,0,0,0,0,0),
    ind3_vs_ind1 = c(0, 0, 0,1,0,0,0,0,0),
    ind4_vs_ind1 = c(0, 0, 0,0,1,0,0,0,0),
    ind5_vs_ind1 = c(0, 0, 0,0,0,1,0,0,0),
    ind6_vs_ind1 = c(0, 0, 0,0,0,0,1,0,0),
    ind7_vs_ind1 = c(0, 0, 0,0,0,0,0,1,0),
    ind8_vs_ind1 = c(0, 0, 0,0,0,0,0,0,1))

cfit2 <- contrasts.fit(fit, t(K2))
efit2 <- eBayes(cfit2, trend=TRUE)
topTable(efit2)

# A shortcut would be to use contrasts.fit(fit, coefficients=3:9) here
# instead, or to specify a set of coefficients directly to topTable().

# 7.6 Challenge - find genes that changed between specific mouse embryos ----
#
# Construct and use contrasts to find genes that changed between:
#
# 1. ind1 and ind8
#
# 2. ind2 and ind3
#
# 7.7 Challenge - find smoothly changing genes ----
#
# Use limma to find genes where the hypothesis that expression is
# changing linearly or quadratically over time is significantly better
# than the hypothesis that they are not changing over time.
#
# Your model should allow that the upper and lower teeth may differ in
# expression level by a constant amount.
#
# As an extension, also allow that they they may follow different
# curves. Do any genes follow different curves in the upper and lower
# teeth, other than differing by a constant amount? (This is something
# we couldn't test for in the above analysis, which treated time as
# categorical, as we would run out of residual degrees of freedom. By
# assuming a smooth change over time we can recover some residual
# degrees of freedom and test for this even without having replicates at
# any of the time points!)
