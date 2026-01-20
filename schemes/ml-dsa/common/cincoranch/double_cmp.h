
#ifndef __DOUBLE_CMP_H
#define __DOUBLE_CMP_H

#ifndef  DATA_TYPE   
  typedef double data_t;
#endif

int compare_double(data_t f1, data_t f2)
 {
  data_t precision =(data_t) 0.000001;
  if (((f1 - precision) > f2) ||  ((f1 + precision) < f2)) return 0;
  return 1;  
 }


int verify_Double(int n,   data_t* test,   data_t* verify)
{
  int i;
  for (i = 0; i < n; i++)
  {
    if( !compare_double(test[i],verify[i])){
      //printf("Error: n=%d,%f!=%f\n",i,test[i],verify[i]);
      return i+1;
    }
  }
    return 0;
}


int mt_verify(const size_t coreid, const size_t ncores,const size_t lda , data_t* test,   data_t* verify ){
    size_t i, k, block, start, end;
    block = lda / ncores;
    if ((block*ncores) != lda) block++;
    start = block * coreid;
    end   = start + block;
    if (end > lda) end = lda;
    if (start> lda) return 0;
    return verify_Double(end-start, test + start,  verify+ start);
}

#endif
