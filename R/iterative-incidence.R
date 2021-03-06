#' Solves stochastically for COPD incidence rate equation.
#' @param nIterations number of iterations for the numberical solution
#' @param nPatients number of simulated agents.
#' @param time_horizon in years
#' @return regression co-efficients as files
#' @export
iterate_COPD_inc<-function(nIterations=500,
                           nPatients=100000,
                           time_horizon=20)
{

    latest_COPD_inc_logit <- cbind(
    male =c(Intercept =0, age = 0 ,age2 = 0, pack_years = 0, smoking_status = 0, year = 0, asthma = 0)
    ,female =c(Intercept =0, age = 0, age2 =0, pack_years = 0, smoking_status = 0, year = 0, asthma = 0))


#  cat("iteration", "intercept_men", "age_coeff_men", "packyears_coeff_men", "intercept_women", "age_coeff_women", "packyears_coeff_women", file="iteration_coeff.csv",sep=",",append=FALSE, fill=FALSE)
#  cat("\n",file="iteration_coeff.csv",sep=",",append=TRUE)

#  cat("iteration","resid_intercept_men", "resid_age_coeff_men", "resid_packyears_coeff_men", "resid_intercept_women", "resid_packyears_coeff_women" ,"resid_age_coeff_women" , file="iteration_resid.csv",sep=",",append=FALSE, fill=FALSE)
#  cat("\n",file="iteration_resid.csv",sep=",",append=TRUE)

  for (i in 1:nIterations){

    settings<-default_settings
    settings$record_mode<-record_mode["record_mode_some_event"]
    settings$events_to_record = c(1)
    settings$agent_stack_size<-0
    settings$n_base_agents<- nPatients
    settings$event_stack_size <- 1e+06 * 1.7 * 30
    init_session(settings=settings)
    input<-model_input$values

    input$COPD$ln_h_COPD_betas_by_sex <- latest_COPD_inc_logit

    run(input=input)
    data<-as.data.frame(Cget_all_events_matrix())
    terminate_session()

    dataF<-data[which(data[,'event']==events["event_fixed"]),]
    dataF[,'age']<-dataF[,'local_time']+dataF[,'age_at_creation']
    dataF[,'copd']<-(dataF[,'gold']>0)*1
    dataF[,'gold2p']<-(dataF[,'gold']>1)*1
    dataF[,'gold3p']<-(dataF[,'gold']>2)*1
    dataF[,'year']<-dataF[,'local_time']+dataF[,'time_at_creation']

    res_male<-glm(data=dataF[which(dataF[,'sex']==0),],formula=copd~age+pack_years+smoking_status,family=binomial(link=logit))
    coefficients(res_male)

    res_female<-glm(data=dataF[which(dataF[,'sex']==1),],formula=copd~age+pack_years+smoking_status,family=binomial(link=logit))
    coefficients(res_female)

    latest_COPD_prev_logit <- cbind(
      male =c(Intercept =summary(res_male)$coefficients[1,1],age = summary(res_male)$coefficients[2,1] ,age2 = 0, pack_years = summary(res_male)$coefficients[3,1], smoking_status = summary(res_male)$coefficients[4,1],year = 0,asthma = 0)
      ,female =c(Intercept =summary(res_female)$coefficients[1,1] ,age = summary(res_female)$coefficients[2,1], age2 =0, pack_years = summary(res_female)$coefficients[3,1], smoking_status = summary(res_female)$coefficients[4,1] ,year = 0,asthma = 0))

    residual <-  input$COPD$logit_p_COPD_betas_by_sex-latest_COPD_prev_logit
    message(c(i, "th loop:"))
    message ("residual is:")
    print (residual)

    cat(i, residual[1,1], residual[2,1], residual[4,1], residual[1,2], residual[2,2], residual[4,2], file="iteration_resid.csv",sep=",",append=TRUE, fill=FALSE)
    cat("\n",file="iteration_resid.csv",sep=",",append=TRUE)


    latest_COPD_inc_logit <- latest_COPD_inc_logit+residual;

    message ("latest inc logit is:")
    print (latest_COPD_inc_logit)

    cat(i, latest_COPD_inc_logit[1,1], latest_COPD_inc_logit[2,1], latest_COPD_inc_logit[4,1], latest_COPD_inc_logit[1,2], latest_COPD_inc_logit[2,2], latest_COPD_inc_logit[4,2], file="iteration_coeff.csv",sep=",",append=TRUE, fill=FALSE)
    cat("\n",file="iteration_coeff.csv",sep=",",append=TRUE)


  }

  iteration_coeff <- readr::read_csv("./iteration_coeff.csv")
  iteration_resid <- readr::read_csv("./iteration_resid.csv")


  print( ggplot2::qplot(iteration, age_coeff_men, data=iteration_coeff, size=I(1), main = "Age Coefficient Convergence for Men") )
  print( ggplot2::qplot(iteration, age_coeff_women, data=iteration_coeff, size=I(1), main = "Age Coefficient Convergence for Women") )

  print( ggplot2::qplot(iteration, packyears_coeff_men, data=iteration_coeff, size=I(1), main = "Smoking (packyears) Coefficient Convergence for Men") )
  print( ggplot2::qplot(iteration, packyears_coeff_women, data=iteration_coeff, size=I(1), main = "Smoking (packyears) Coefficient Convergence for women") )

  print( ggplot2::qplot(iteration, intercept_men, data=iteration_coeff, size=I(1), main = "Logit intercept Convergence for Men") )
  print( ggplot2::qplot(iteration, intercept_women, data=iteration_coeff, size=I(1), main = "Logit intercept Convergence for women") )


  print( ggplot2::qplot(iteration, resid_age_coeff_men, data=iteration_resid, size=I(1), main = "Residue for Age Coefficient - Men") )
  print( ggplot2::qplot(iteration, resid_age_coeff_women, data=iteration_resid, size=I(1), main = "Residue for Age Coefficient - Women") )

  print( ggplot2::qplot(iteration, resid_packyears_coeff_men, data=iteration_resid, size=I(1),  main = "Residue for Cigarette Smoking (packyears) Coefficient - Men") )
  print( ggplot2::qplot(iteration, resid_packyears_coeff_women, data=iteration_resid, size=I(1),  main = "Residue for Cigarette Smoking (packyears) Coefficient - Women") )

  print( ggplot2::qplot(iteration, resid_intercept_men, data=iteration_resid, size=I(1),  main = "Residue for logit intercept - Men") )
  print( ggplot2::qplot(iteration, resid_intercept_women, data=iteration_resid, size=I(1),  main = "Residue for logit intercept - Women") )


  res_male<-glm(data=dataF[which(dataF[,'sex']==0),],formula=copd~age+pack_years+year,family=binomial(link=logit))
  print( coefficients(res_male) )

  res_female<-glm(data=dataF[which(dataF[,'sex']==1),],formula=copd~age+pack_years+year,family=binomial(link=logit))
  print( coefficients(res_female) )


}
