#### TRONCO: a tool for TRanslational ONCOlogy
####
#### Copyright (c) 2015-2017, Marco Antoniotti, Giulio Caravagna, Luca De Sano,
#### Alex Graudenzi, Giancarlo Mauri, Bud Mishra and Daniele Ramazzotti.
####
#### All rights reserved. This program and the accompanying materials
#### are made available under the terms of the GNU GPL v3.0
#### which accompanies this distribution.


# reconstruct the best topology based on probabilistic causation and Chow Liu algorithm
# @title chow.liu.fit
# @param dataset a dataset describing a progressive phenomenon
# @param regularization regularizators to be used for the likelihood fit
# @param do.boot should I perform bootstrap? Yes if TRUE, no otherwise
# @param nboot integer number (greater than 0) of bootstrap sampling to be performed
# @param pvalue pvalue for the tests (value between 0 and 1)
# @param min.boot minimum number of bootstrapping to be performed
# @param min.stat should I keep bootstrapping untill I have nboot valid values?
# @param boot.seed seed to be used for the sampling
# @param silent should I be verbose?
# @param epos error rate of false positive errors
# @param eneg error rate of false negative errors
# @param hypotheses hypotheses to be considered in the reconstruction. This should be NA for this algorithms. 
# @return topology: the reconstructed tree topology
#
chow.liu.fit <- function(dataset,
                         regularization = c("bic","aic"),
                         do.boot = TRUE,
                         nboot = 100,
                         pvalue = 0.05,
                         min.boot = 3,
                         min.stat = TRUE,
                         boot.seed = NULL,
                         silent = FALSE,
                         epos = 0.0,
                         eneg = 0.0,
                         hypotheses = NA) {

    ## Start the clock to measure the execution time.
    
    ptm = proc.time();

    ## Structure with the set of valid edges
    ## I start from the complete graph, i.e., I have no prior and all
    ## the connections are possibly causal.
    
    adj.matrix = array(1, c(ncol(dataset), ncol(dataset)));
    colnames(adj.matrix) = colnames(dataset);
    rownames(adj.matrix) = colnames(dataset);

    ## The diagonal of the adjacency matrix should not be considered,
    ## i.e., no self cause is allowed.
    
    diag(adj.matrix) = 0;

    ## Consider any hypothesis.
    
    adj.matrix = hypothesis.adj.matrix(hypotheses, adj.matrix);

    ## Check if the dataset is valid.
    
    valid.dataset = check.dataset(dataset, adj.matrix, FALSE, epos, eneg)
    adj.matrix = valid.dataset$adj.matrix;
    invalid.events = valid.dataset$invalid.events;

    ## Reconstruct the prima facie topology
    ## Should I perform bootstrap? Yes if TRUE, no otherwise.
    
    if (do.boot == TRUE) {
        if (!silent)
            cat('*** Bootstraping selective advantage scores (prima facie).\n')
        prima.facie.parents =
            get.prima.facie.parents.do.boot(dataset,
                                            hypotheses,
                                            nboot,
                                            pvalue,
                                            adj.matrix,
                                            min.boot,
                                            min.stat,
                                            boot.seed,
                                            silent,
                                            epos,
                                            eneg);
    } else {
        if (!silent)
            cat('*** Computing selective advantage scores (prima facie).\n')
        prima.facie.parents =
            get.prima.facie.parents.no.boot(dataset,
                                            hypotheses,
                                            adj.matrix,
                                            silent,
                                            epos,
                                            eneg);
    }

    ## Add back in any connection invalid for the probability raising
    ## theory.
    
    if (length(invalid.events) > 0) {
        # save the correct acyclic matrix
        adj.matrix.cyclic.tp.valid = prima.facie.parents$adj.matrix$adj.matrix.cyclic.tp
        adj.matrix.cyclic.valid = prima.facie.parents$adj.matrix$adj.matrix.cyclic
        adj.matrix.acyclic.valid = prima.facie.parents$adj.matrix$adj.matrix.acyclic
        for (i in 1:nrow(invalid.events)) {
            prima.facie.parents$adj.matrix$adj.matrix.cyclic.tp[invalid.events[i, "cause"],invalid.events[i, "effect"]] = 1
            prima.facie.parents$adj.matrix$adj.matrix.cyclic[invalid.events[i, "cause"],invalid.events[i, "effect"]] = 1
            prima.facie.parents$adj.matrix$adj.matrix.acyclic[invalid.events[i, "cause"],invalid.events[i, "effect"]] = 1
        }
        # if the new cyclic.tp contains cycles use the previously computed matrix
        if (!is.dag(graph.adjacency(prima.facie.parents$adj.matrix$adj.matrix.cyclic.tp))) {
            prima.facie.parents$adj.matrix$adj.matrix.cyclic.tp = adj.matrix.cyclic.tp.valid
        }
        # if the new cyclic contains cycles use the previously computed matrix
        if (!is.dag(graph.adjacency(prima.facie.parents$adj.matrix$adj.matrix.cyclic))) {
            prima.facie.parents$adj.matrix$adj.matrix.cyclic = adj.matrix.cyclic.valid
        }
        # if the new acyclic contains cycles use the previously computed matrix
        if (!is.dag(graph.adjacency(prima.facie.parents$adj.matrix$adj.matrix.acyclic))) {
            prima.facie.parents$adj.matrix$adj.matrix.acyclic = adj.matrix.acyclic.valid
        }
    }
    
    adj.matrix.prima.facie =
        prima.facie.parents$adj.matrix$adj.matrix.acyclic

    ## Perform the likelihood fit with the required strategy.
    
    model = list();
    for (reg in regularization) {

        ## Perform the likelihood fit with the chosen regularization
        ## score on the prima facie topology.
        
        if (!silent)
            cat('*** Performing likelihood-fit with regularization',reg,'.\n')
        best.parents =
            perform.likelihood.fit.chow.liu(dataset,
                                   adj.matrix.prima.facie,
                                   regularization = reg);

        ## Set the structure to save the conditional probabilities of
        ## the reconstructed topology.
        
        reconstructed.model = create.model(dataset,
            best.parents,
            prima.facie.parents)

        model.name = paste('chow_liu', reg, sep='_')
        model[[model.name]] = reconstructed.model
    }

    ## Set the execution parameters.
    
    parameters =
        list(algorithm = "CHOW_LIU",
             regularization = regularization,
             do.boot = do.boot,
             nboot = nboot,
             pvalue = pvalue,
             min.boot = min.boot,
             min.stat = min.stat,
             boot.seed = boot.seed,
             silent = silent,
             error.rates = list(epos=epos,eneg=eneg));

    ## Return the results.
    
    topology =
        list(dataset = dataset,
             hypotheses = hypotheses,
             adj.matrix.prima.facie = adj.matrix.prima.facie,
             confidence = prima.facie.parents$pf.confidence,
             model = model,
             parameters = parameters,
             execution.time = (proc.time() - ptm))
    topology = rename.reconstruction.fields(topology, dataset)
    return(topology)
}


# reconstruct the best causal topology by Chow Liu algorithm combined with probabilistic causation
# @title perform.likelihood.fit.chow.liu
# @param dataset a valid dataset
# @param adj.matrix the adjacency matrix of the prima facie causes
# @param regularization regularization term to be used in the likelihood fit
# @param command type of search, either hill climbing (hc) or tabu (tabu)
# @return topology: the adjacency matrix of both the prima facie and causal topologies
#
perform.likelihood.fit.chow.liu = function( dataset, 
                                            adj.matrix,
                                            regularization,
                                            command = "hc") {

    ## Each variable should at least have 2 values: I'm ignoring
    ## connection to invalid events but, still, need to make the
    ## dataset valid for bnlearn.
    
    for (i in 1:ncol(dataset)) {
        if (sum(dataset[, i]) == 0) {
            dataset[sample(1:nrow(dataset), size=1), i] = 1;
        } else if (sum(dataset[, i]) == nrow(dataset)) {
            dataset[sample(1:nrow(dataset), size=1), i] = 0;
        }
    }

    # adjacency matrix of the topology reconstructed by likelihood fit
    adj.matrix.fit = array(0,c(nrow(adj.matrix),ncol(adj.matrix)))
    rownames(adj.matrix.fit) = colnames(dataset)
    colnames(adj.matrix.fit) = colnames(dataset)

    ## Create the blacklist based on the prima facie topology
    ## and the tree-structure assumption
    cont = 0
    parent = -1
    child = -1

    fully_disconnected = NULL
    for (i in rownames(adj.matrix)) {
        if((sum(adj.matrix[,i])+sum(adj.matrix[i,]))==0) {
            fully_disconnected = c(fully_disconnected,i)
        }
        for (j in colnames(adj.matrix)) {
            if(i != j && adj.matrix[i, j] == 0 && adj.matrix[j, i] == 0) {
                cont = cont + 1
                if (cont == 1) {
                    parent = i
                    child = j
                } else {
                    parent = c(parent, i)
                    child = c(child, j)
                }
            }
        }
    }

    # compute the best Chow-Liu tree among the valid edges
    if(length(fully_disconnected)<ncol(dataset)) {

        valid_data_entries = colnames(dataset)
        if(length(fully_disconnected)>0) {
            valid_data_entries = colnames(dataset)[which(!colnames(dataset)%in%fully_disconnected)]
        }

        if (cont > 0) {

            blacklist = data.frame(from = parent,to = child)
            if(length(fully_disconnected)>0) {
                blacklist = blacklist[which(blacklist$from%in%valid_data_entries&blacklist$to%in%valid_data_entries),]
            }

            if(dim(blacklist)[1]>0) {
                best_chow_liu_tree = tryCatch({
                            chow.liu(x=as.categorical.dataset(dataset[,valid_data_entries]),blacklist=blacklist)
                        }, error = function(e) {
                            NA
                        })
            }
            else {
                best_chow_liu_tree = tryCatch({
                            chow.liu(x=as.categorical.dataset(dataset[,valid_data_entries]))
                        }, error = function(e) {
                            NA
                        })
            }

        } else {
            best_chow_liu_tree = tryCatch({
                            chow.liu(x=as.categorical.dataset(dataset[,valid_data_entries]))
                        }, error = function(e) {
                            NA
                        })
        }

    }

    if(!any(is.na(best_chow_liu_tree)) && length(fully_disconnected)<ncol(dataset)) {

        # get the best topology considering both the priors and the Chow-Liu tree
        my.arcs = best_chow_liu_tree$arcs
        
        ## build the adjacency matrix of the reconstructed topology
        if (length(nrow(my.arcs)) > 0 && nrow(my.arcs) > 0) {
            for (i in 1:nrow(my.arcs)) {
                # [i,j] refers to causation i --> j
                if(adj.matrix[my.arcs[i,1],my.arcs[i,2]]==1) {
                    adj.matrix.fit[my.arcs[i,1],my.arcs[i,2]] = 1
                }
            }
        }

    }

    if(!any(is.na(best_chow_liu_tree))) {

        ## Perform the likelihood fit if requested
        adj.matrix.fit = lregfit(as.categorical.dataset(dataset),
            adj.matrix,
            adj.matrix.fit,
            regularization,
            command)

    }
    else {
        warning("A tree spanning all the node could not be obtained.")
    }
    
    ## Save the results and return them.
    
    adj.matrix =
        list(adj.matrix.pf = adj.matrix,
             adj.matrix.fit = adj.matrix.fit);
    topology = list(adj.matrix = adj.matrix);
    return(topology)

}

#### end of file -- chow.liu.algorithm.R
