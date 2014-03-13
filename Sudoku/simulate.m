%
clear all;
ConstructsInLibrary=5120;
PlateFormat=96;
PlatesPicked=50;
NumberOfPools=3;
PoolSizes=[59 61 67];

%Pick plates
disp('Picking plates');
ClonesPicked=randi(ConstructsInLibrary,PlateFormat,PlatesPicked);
ClonesPickedLinear=ClonesPicked(:);
ConstructsFoundBack=0;
for Construct=1:ConstructsInLibrary
    if(find(ClonesPickedLinear==Construct))
        ConstructsFoundBack=ConstructsFoundBack+1;
    end
end
disp([num2str(ConstructsFoundBack) ' constructs out of ' num2str(ConstructsInLibrary) ' were present in ' num2str(size(ClonesPickedLinear,1)) ' clones.']);

%Put clones in pools
disp('Putting clones in pools');
PooledClones{max(PoolSizes),NumberOfPools}=[];
for Pool=1:NumberOfPools
    PoolPosition=0;
    for Clone=1:size(ClonesPickedLinear,1)
        PoolPosition=PoolPosition+1;
        PooledClones{PoolPosition,Pool}=[PooledClones{PoolPosition,Pool} Clone];
        if(PoolPosition>=PoolSizes(Pool))
            PoolPosition=0;
        end
    end
end

%Sequence
disp('Sequencing');
SequencedConstructs{ConstructsInLibrary}=[];
for Pool=1:NumberOfPools
    for PoolPosition=1:PoolSizes(Pool)
        for i=1:size(PooledClones{PoolPosition,Pool},2)
            SequencedConstructs{ClonesPickedLinear(PooledClones{PoolPosition,Pool}(i))}=[ SequencedConstructs{ClonesPickedLinear(PooledClones{PoolPosition,Pool}(i))};[PoolPosition Pool]];
        end
    end
end

%Try to find back clones
disp('Mapping back clones to library sequences');
PossibleClonesForSequence{ConstructsInLibrary}=[];
ClonesNotFound=0;
for Construct=1:ConstructsInLibrary
    if(SequencedConstructs{Construct})
        %If a sequence x is read, find all possible intersects of what
        %clone this could represent
        Pool1Positions=SequencedConstructs{Construct}(find(SequencedConstructs{Construct}(:,2)==1),1);
        Pool2Positions=SequencedConstructs{Construct}(find(SequencedConstructs{Construct}(:,2)==2),1);
        Pool3Positions=SequencedConstructs{Construct}(find(SequencedConstructs{Construct}(:,2)==3),1);
        for i=Pool1Positions'
            for j=Pool2Positions'
                for k=Pool3Positions'
                    PossibleClonesForSequence{Construct}=[PossibleClonesForSequence{Construct} intersect(intersect(PooledClones{i,1},PooledClones{j,2}),PooledClones{k,3})];
                end
            end
        end
    else
        ClonesNotFound=ClonesNotFound+1;
    end
    PossibleClonesForSequence{Construct}=unique(PossibleClonesForSequence{Construct});
end

%Detect clones with unambiguous identification
disp('Determine unambiguosly mapped clones');
UnambiguouslyMapped=0;
ClonesNotMapped=0;
for Clone=1:size(ClonesPickedLinear,1)
     NumberOfSequencesFoundThatItMayBelongTo=0;
     for Construct=1:ConstructsInLibrary
         if(find(PossibleClonesForSequence{Construct}==Clone)) 
             NumberOfSequencesFoundThatItMayBelongTo=NumberOfSequencesFoundThatItMayBelongTo+1;
             BelongsToConstruct=Construct;
         end
     end
     MappedClones(Clone)=0;
     if(NumberOfSequencesFoundThatItMayBelongTo==1) 
         MappedClones(Clone)=BelongsToConstruct;
         UnambiguouslyMapped=UnambiguouslyMapped+1;
     end
     if(NumberOfSequencesFoundThatItMayBelongTo==0) 
         ClonesNotMapped=ClonesNotMapped+1;
     end    
end
disp([num2str(UnambiguouslyMapped) ' clones out of ' num2str(size(ClonesPickedLinear,1)) ' were unambiguously assigned.']);

%Detect how many constructs are found back
disp('Determine how many constructs are found back');
ConstructsFoundBack=0;
for Construct=1:ConstructsInLibrary
    if(find(MappedClones==Construct))
        ConstructsFoundBack=ConstructsFoundBack+1;
    end
end
disp([num2str(ConstructsFoundBack) ' constructs out of ' num2str(ConstructsInLibrary) ' were found back.']);
% 
%                 
%                 